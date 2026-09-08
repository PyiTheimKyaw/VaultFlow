import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

import '../helpers.dart';

void main() {
  late FakeClock clock;
  late ServerContext ctx;
  late AuthService auth;

  const creds = CredentialsRequest(
    email: 'Me@Example.com',
    password: 'correct horse',
    deviceName: 'Mac',
    platform: 'macos',
  );

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 9, 6, 12));
    ctx = testContext(clock: clock);
    auth = ctx.auth;
  });

  ApiErrorCode codeOf(Object? e) => (e! as ApiException).code;

  group('register', () {
    test('creates the user, device and a token family', () async {
      final tokens = await auth.register(creds);
      expect(tokens.userId, isNotEmpty);
      expect(tokens.deviceId, isNotEmpty);
      expect(tokens.expiresIn, 900);
      final claims = ctx.tokens.verifyAccessToken(tokens.accessToken);
      expect(claims.userId, tokens.userId);
      expect(claims.deviceId, tokens.deviceId);
      final user = await ctx.store.findUserByEmail('me@example.com');
      expect(user, isNotNull);
      expect(user!.passwordHash, startsWith(r'$argon2id$'));
    });

    test('rejects duplicate emails case-insensitively', () async {
      await auth.register(creds);
      await expectLater(
        auth.register(creds.copyWith(email: 'ME@example.com')),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.emailTaken)),
      );
    });

    test('validates email, password and platform', () async {
      await expectLater(
        auth.register(creds.copyWith(email: 'nope')),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.validationFailed)),
      );
      await expectLater(
        auth.register(creds.copyWith(password: 'short')),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.validationFailed)),
      );
      await expectLater(
        auth.register(creds.copyWith(platform: 'toaster')),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.validationFailed)),
      );
    });
  });

  group('login', () {
    test('succeeds with the right password and reuses the device id', () async {
      final first = await auth.register(creds);
      final again = await auth.login(creds.copyWith(deviceId: first.deviceId));
      expect(again.deviceId, first.deviceId);
      expect(again.userId, first.userId);
      expect(again.refreshToken, isNot(first.refreshToken));
    });

    test('rejects wrong password and unknown email identically', () async {
      await auth.register(creds);
      await expectLater(
        auth.login(creds.copyWith(password: 'wrong password')),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.unauthorized)),
      );
      await expectLater(
        auth.login(creds.copyWith(email: 'nobody@example.com')),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.unauthorized)),
      );
    });

    test(
      'does not let a device id owned by another user be hijacked',
      () async {
        final a = await auth.register(creds);
        final b = await auth.register(
          creds.copyWith(email: 'other@example.com', deviceId: a.deviceId),
        );
        expect(b.deviceId, isNot(a.deviceId));
      },
    );
  });

  group('refresh', () {
    test('rotates the token and keeps the old one unusable', () async {
      final first = await auth.register(creds);
      clock.advance(const Duration(minutes: 1));
      final second = await auth.refresh(
        RefreshRequest(
          refreshToken: first.refreshToken,
          deviceId: first.deviceId,
        ),
      );
      expect(second.refreshToken, isNot(first.refreshToken));
      expect(second.deviceId, first.deviceId);

      // Presenting the rotated token again is treated as theft: the whole
      // family, including the freshly issued token, is revoked.
      await expectLater(
        auth.refresh(
          RefreshRequest(
            refreshToken: first.refreshToken,
            deviceId: first.deviceId,
          ),
        ),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.tokenRevoked)),
      );
      await expectLater(
        auth.refresh(
          RefreshRequest(
            refreshToken: second.refreshToken,
            deviceId: second.deviceId,
          ),
        ),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.tokenRevoked)),
      );
    });

    test('rejects tokens from another device and unknown tokens', () async {
      final first = await auth.register(creds);
      await expectLater(
        auth.refresh(
          RefreshRequest(refreshToken: first.refreshToken, deviceId: 'other'),
        ),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.tokenRevoked)),
      );
      await expectLater(
        auth.refresh(
          const RefreshRequest(refreshToken: 'garbage', deviceId: 'x'),
        ),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.tokenRevoked)),
      );
    });

    test('expired refresh tokens are rejected', () async {
      final first = await auth.register(creds);
      clock.advance(const Duration(days: 31));
      await expectLater(
        auth.refresh(
          RefreshRequest(
            refreshToken: first.refreshToken,
            deviceId: first.deviceId,
          ),
        ),
        throwsA(predicate((e) => codeOf(e) == ApiErrorCode.tokenExpired)),
      );
    });

    test(
      'a new login is a separate family and survives revocation of the old one',
      () async {
        final a = await auth.register(creds);
        final b = await auth.login(creds);
        await auth.logout(
          RefreshRequest(refreshToken: a.refreshToken, deviceId: a.deviceId),
        );
        await expectLater(
          auth.refresh(
            RefreshRequest(refreshToken: a.refreshToken, deviceId: a.deviceId),
          ),
          throwsA(predicate((e) => codeOf(e) == ApiErrorCode.tokenRevoked)),
        );
        final refreshed = await auth.refresh(
          RefreshRequest(refreshToken: b.refreshToken, deviceId: b.deviceId),
        );
        expect(refreshed.userId, b.userId);
      },
    );
  });

  group('access tokens', () {
    test('expire after the ttl', () async {
      final tokens = await auth.register(creds);
      clock.advance(const Duration(minutes: 14));
      expect(
        ctx.tokens.verifyAccessToken(tokens.accessToken).userId,
        tokens.userId,
      );
      clock.advance(const Duration(minutes: 2));
      expect(
        () => ctx.tokens.verifyAccessToken(tokens.accessToken),
        throwsA(
          isA<AccessTokenException>().having(
            (e) => e.reason,
            'reason',
            AccessTokenError.expired,
          ),
        ),
      );
    });

    test('tampered or foreign tokens are invalid', () async {
      final tokens = await auth.register(creds);
      final other = TokenService(
        secret: 'another-secret',
        accessTokenTtl: const Duration(minutes: 15),
        clock: clock,
      );
      expect(
        () => other.verifyAccessToken(tokens.accessToken),
        throwsA(isA<AccessTokenException>()),
      );
      expect(
        () => ctx.tokens.verifyAccessToken('${tokens.accessToken}x'),
        throwsA(isA<AccessTokenException>()),
      );
    });
  });
}
