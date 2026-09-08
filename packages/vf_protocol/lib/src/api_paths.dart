/// Route constants shared by the server (for routing tests) and the client.
///
/// All paths are relative to the API base URL and have no trailing slash.
abstract final class ApiPaths {
  static const String health = '/health';

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String syncPush = '/sync/push';
  static const String syncChanges = '/sync/changes';
  static const String syncEvents = '/sync/events';

  static const String uploads = '/uploads';
  static String upload(String uploadId) => '$uploads/$uploadId';
  static String uploadChunk(String uploadId, int index) =>
      '$uploads/$uploadId/chunks/$index';
  static String uploadComplete(String uploadId) =>
      '$uploads/$uploadId/complete';

  static String documentContent(String documentId) =>
      '/documents/$documentId/content';

  /// Header carrying `vfProtocolVersion`.
  static const String protocolHeader = 'X-VaultFlow-Protocol';

  /// Header carrying the hex sha256 of a chunk body.
  static const String chunkHashHeader = 'X-Chunk-Sha256';

  /// Header carrying a per-request id for log correlation.
  static const String requestIdHeader = 'X-Request-Id';
}
