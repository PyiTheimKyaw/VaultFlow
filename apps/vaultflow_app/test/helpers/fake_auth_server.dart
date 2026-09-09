import 'package:dio/dio.dart';
import 'package:vf_network/testing.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// In-memory stand-in for the auth routes, good enough for widget tests.
class FakeAuthServer {
  FakeAuthServer() {
    adapter
      ..on('POST', ApiPaths.authRegister, _register)
      ..on('POST', ApiPaths.authLogin, _login)
      ..on('POST', ApiPaths.authRefresh, _refresh)
      ..on('POST', ApiPaths.authLogout, (_) {
        logouts++;
        return const FakeResponse(204);
      })
      ..on('GET', ApiPaths.authMe, _me)
      ..on('POST', '/documents/*', _downloadUrl);
  }

  /// Ids of documents a download link was issued for.
  final List<String> downloadLinks = [];

  FakeResponse _downloadUrl(RequestOptions o) {
    final id = o.path.split('/')[2];
    downloadLinks.add(id);
    return FakeResponse(200, {
      'url': '/documents/$id/content?token=signed-$id',
      'expires_at': '2026-09-07T09:05:00.000Z',
    });
  }

  final adapter = FakeAdapter();
  final Map<String, String> users = {};
  int logouts = 0;
  int _counter = 0;

  /// When set, every request fails as if the network were down.
  bool offline = false;

  FakeResponse _error(int status, String code, String message) =>
      FakeResponse(status, {
        'error': {'code': code, 'message': message},
      });

  Map<String, Object?> _tokens(String email) => {
    'access_token': 'access-${++_counter}',
    'refresh_token': 'refresh-$_counter',
    'device_id': 'device-1',
    'user_id': 'user-$email',
    'expires_in': 900,
  };

  FakeResponse _register(RequestOptions o) {
    if (offline) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    final body = o.data as Map;
    final email = (body['email'] as String).toLowerCase();
    if (users.containsKey(email)) {
      return _error(
        409,
        'email_taken',
        'An account with this email already exists',
      );
    }
    users[email] = body['password'] as String;
    return FakeResponse(201, _tokens(email));
  }

  FakeResponse _login(RequestOptions o) {
    if (offline) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    final body = o.data as Map;
    final email = (body['email'] as String).toLowerCase();
    if (users[email] != body['password']) {
      return _error(401, 'unauthorized', 'Incorrect email or password');
    }
    return FakeResponse(200, _tokens(email));
  }

  FakeResponse _refresh(RequestOptions o) =>
      FakeResponse(200, _tokens('refreshed'));

  FakeResponse _me(RequestOptions o) {
    final auth = o.headers['Authorization'] as String?;
    if (auth == null) return _error(401, 'unauthorized', 'no token');
    return const FakeResponse(200, {
      'user_id': 'user-me@example.com',
      'email': 'me@example.com',
      'device_id': 'device-1',
    });
  }
}
