import 'dart:convert';

import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_security/vf_security.dart';

/// [TokenStore] on the platform keychain: one JSON blob under a single key.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore(this._store);

  static const String key = 'vf.session.v1';

  final SecureStore _store;

  @override
  Future<AuthTokens?> read() async {
    final raw = await _store.read(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthTokens.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      // A corrupt blob is treated as signed out rather than crashing.
      await _store.delete(key);
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) =>
      _store.write(key, jsonEncode(tokens.toJson()));

  @override
  Future<void> clear() => _store.delete(key);
}
