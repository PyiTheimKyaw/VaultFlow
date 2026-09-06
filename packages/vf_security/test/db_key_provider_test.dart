import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vf_security/vf_security.dart';

void main() {
  test('generates a 32-byte key once and reuses it', () async {
    final store = InMemorySecureStore();
    final provider = DbKeyProvider(store, random: Random(42));
    final first = await provider.getOrCreate();
    final second = await provider.getOrCreate();
    expect(first, second);
    expect(first.length, greaterThanOrEqualTo(43));
    expect(store.values[DbKeyProvider.storageKey], first);
    expect(first, isNot(contains("'")));
  });

  test('different stores get different keys', () async {
    final a = await DbKeyProvider(InMemorySecureStore()).getOrCreate();
    final b = await DbKeyProvider(InMemorySecureStore()).getOrCreate();
    expect(a, isNot(b));
  });

  test('reset forgets the key', () async {
    final store = InMemorySecureStore();
    final provider = DbKeyProvider(store);
    final first = await provider.getOrCreate();
    await provider.reset();
    expect(store.values, isEmpty);
    expect(await provider.getOrCreate(), isNot(first));
  });

  test('InMemorySecureStore deleteAll clears everything', () async {
    final store = InMemorySecureStore();
    await store.write('a', '1');
    await store.write('b', '2');
    await store.deleteAll();
    expect(await store.read('a'), isNull);
  });
}
