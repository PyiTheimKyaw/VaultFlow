import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/http/api_exception.dart';
import 'package:vaultflow_server/http/request_helpers.dart';
import 'package:vaultflow_server/server_context.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Fixed-window counter per key, in memory (one process). Good enough to
/// blunt brute force and runaway clients; a shared store would be needed
/// for a multi-instance deployment.
class RateLimiter {
  RateLimiter({
    required this.limit,
    this.window = const Duration(minutes: 1),
    this.clock = const SystemClock(),
  });

  /// Requests allowed per [window]; `0` disables limiting.
  final int limit;
  final Duration window;
  final Clock clock;

  final Map<String, ({DateTime start, int count})> _buckets = {};

  bool get enabled => limit > 0;

  /// Records one request for [key]. Returns the seconds until the window
  /// resets when the key is over budget, `null` when allowed.
  int? hit(String key) {
    if (!enabled) return null;
    final now = clock.now();
    final bucket = _buckets[key];
    if (bucket == null || now.difference(bucket.start) >= window) {
      _buckets[key] = (start: now, count: 1);
      if (_buckets.length > 10000) _evict(now);
      return null;
    }
    if (bucket.count >= limit) {
      return window.inSeconds - now.difference(bucket.start).inSeconds;
    }
    _buckets[key] = (start: bucket.start, count: bucket.count + 1);
    return null;
  }

  /// Remaining budget for [key] in the current window.
  int remaining(String key) {
    final bucket = _buckets[key];
    if (bucket == null || clock.now().difference(bucket.start) >= window) {
      return limit;
    }
    return (limit - bucket.count).clamp(0, limit);
  }

  void _evict(DateTime now) {
    _buckets.removeWhere((_, b) => now.difference(b.start) >= window);
  }
}

/// The client address for rate limiting: the first `X-Forwarded-For` hop
/// when [trustProxy], else the socket address.
String clientKey(RequestContext context, {required bool trustProxy}) {
  if (trustProxy) {
    final forwarded = context.request.headers['x-forwarded-for'];
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }
  }
  try {
    return context.request.connectionInfo.remoteAddress.address;
  } on Object {
    // No socket behind the request (tests, embedded handlers).
    return 'unknown';
  }
}

/// 429 with `Retry-After` once [limiter] is exhausted for the key chosen
/// by [keyFor]. Responses carry `X-RateLimit-Remaining`.
Middleware rateLimit(
  RateLimiter limiter, {
  required String Function(RequestContext context) keyFor,
}) {
  return (handler) => (context) async {
    if (!limiter.enabled) return await handler(context);
    // Preflights are cheap and must never be blocked.
    if (context.request.method == HttpMethod.options) {
      return await handler(context);
    }
    final key = keyFor(context);
    final retryAfter = limiter.hit(key);
    if (retryAfter != null) {
      throw ApiException(
        ApiErrorCode.rateLimited,
        'Too many requests; retry in ${retryAfter}s',
        headers: {'Retry-After': '$retryAfter'},
      );
    }
    final response = await handler(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        'X-RateLimit-Limit': '${limiter.limit}',
        'X-RateLimit-Remaining': '${limiter.remaining(key)}',
      },
    );
  };
}

/// Per-user key once authenticated, else per client address.
String userOrClientKey(RequestContext context, {required bool trustProxy}) {
  final token = bearerToken(context);
  if (token != null) {
    try {
      final claims = context.read<ServerContext>().tokens.verifyAccessToken(
        token,
      );
      return 'user:${claims.userId}';
    } on Object {
      // Invalid token: fall through to the address so bad tokens still
      // burn the client's budget.
    }
  }
  return 'ip:${clientKey(context, trustProxy: trustProxy)}';
}
