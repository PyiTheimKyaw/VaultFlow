import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

void main() {
  final hasher = PasswordHasher(memoryKiB: 256, iterations: 1);

  test('hash produces a PHC string and verifies', () async {
    final encoded = await hasher.hash('hunter22');
    expect(encoded, startsWith(r'$argon2id$v=19$m=256,t=1,p=1$'));
    expect(await hasher.verify('hunter22', encoded), isTrue);
    expect(await hasher.verify('hunter23', encoded), isFalse);
  });

  test('two hashes of the same password differ (random salt)', () async {
    expect(await hasher.hash('same'), isNot(await hasher.hash('same')));
  });

  test('verifies hashes made with other parameters', () async {
    final strong = PasswordHasher(memoryKiB: 512);
    final encoded = await strong.hash('pw');
    expect(await hasher.verify('pw', encoded), isTrue);
  });

  test('malformed strings are rejected without throwing', () async {
    expect(await hasher.verify('pw', ''), isFalse);
    expect(await hasher.verify('pw', r'$argon2id$v=19$m=x$a$b'), isFalse);
    expect(await hasher.verify('pw', r'$bcrypt$something'), isFalse);
  });

  test('constantTimeEquals', () {
    expect(PasswordHasher.constantTimeEquals([1, 2], [1, 2]), isTrue);
    expect(PasswordHasher.constantTimeEquals([1, 2], [1, 3]), isFalse);
    expect(PasswordHasher.constantTimeEquals([1], [1, 2]), isFalse);
  });
}
