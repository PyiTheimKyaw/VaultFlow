import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_network/src/auth_interceptor.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Typed access to the VaultFlow API. Every call returns a [Result]; the
/// error side is one of [NetworkFailure], [AuthFailure], [ServerFailure]
/// or [CancelledFailure].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  static final Options _public = Options(extra: {skipAuthExtra: true});

  Future<Result<AuthTokens>> register(CredentialsRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.authRegister,
      data: request.toJson(),
      options: _public,
    ),
    AuthTokens.fromJson,
  );

  Future<Result<AuthTokens>> login(CredentialsRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.authLogin,
      data: request.toJson(),
      options: _public,
    ),
    AuthTokens.fromJson,
  );

  Future<Result<AuthTokens>> refresh(RefreshRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.authRefresh,
      data: request.toJson(),
      options: _public,
    ),
    AuthTokens.fromJson,
  );

  Future<Result<void>> logout(RefreshRequest request) => _run(
    () => _dio.post<Object?>(
      ApiPaths.authLogout,
      data: request.toJson(),
      options: _public,
    ),
    (_) {},
  );

  // ------------------------------------------------------------------ sync

  Future<Result<PushResponse>> push(PushRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.syncPush,
      data: request.toJson(),
    ),
    PushResponse.fromJson,
  );

  Future<Result<ChangesResponse>> changes({
    required int since,
    int limit = vfMaxChangesPageSize,
    String? excludeDeviceId,
  }) => _run(
    () => _dio.get<Map<String, Object?>>(
      ApiPaths.syncChanges,
      queryParameters: {
        'since': since,
        'limit': limit,
        'exclude_device': ?excludeDeviceId,
      },
    ),
    ChangesResponse.fromJson,
  );

  // -------------------------------------------------------------- transfers

  Future<Result<UploadSessionResponse>> createUpload(
    UploadSessionCreateRequest request,
  ) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.uploads,
      data: request.toJson(),
    ),
    UploadSessionResponse.fromJson,
  );

  Future<Result<UploadSessionStatus>> uploadStatus(String uploadId) => _run(
    () => _dio.get<Map<String, Object?>>(ApiPaths.upload(uploadId)),
    UploadSessionStatus.fromJson,
  );

  /// Sends one raw chunk. [sha256] travels in `X-Chunk-Sha256` so the
  /// server can reject corrupted bodies before touching storage.
  Future<Result<UploadChunkResponse>> putChunk(
    String uploadId,
    int index,
    List<int> bytes, {
    required String sha256,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) => _run(
    () => _dio.put<Map<String, Object?>>(
      ApiPaths.uploadChunk(uploadId, index),
      data: Stream.value(Uint8List.fromList(bytes)),
      options: Options(
        headers: {
          Headers.contentTypeHeader: 'application/octet-stream',
          Headers.contentLengthHeader: bytes.length,
          ApiPaths.chunkHashHeader: sha256,
        },
        sendTimeout: const Duration(minutes: 5),
      ),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    ),
    UploadChunkResponse.fromJson,
  );

  Future<Result<UploadCompleteResponse>> completeUpload(String uploadId) =>
      _run(
        () =>
            _dio.post<Map<String, Object?>>(ApiPaths.uploadComplete(uploadId)),
        UploadCompleteResponse.fromJson,
      );

  /// A short-lived link a browser can open directly (web downloads).
  Future<Result<DownloadUrlResponse>> createDownloadUrl(String documentId) =>
      _run(
        () => _dio.post<Map<String, Object?>>(
          ApiPaths.documentDownloadUrl(documentId),
        ),
        DownloadUrlResponse.fromJson,
      );

  /// Absolute form of a [DownloadUrlResponse.url] for this client's origin.
  Uri absolute(String path) => Uri.parse(_dio.options.baseUrl).resolve(path);

  /// Server-sent events from `GET /sync/events`: each element is the newest
  /// change sequence. Completes when the server closes the stream; the
  /// caller reconnects. Not available on web (the browser adapter buffers
  /// responses).
  Stream<int> syncEvents({String? excludeDeviceId, CancelToken? cancelToken}) {
    final controller = StreamController<int>();
    Future<void> run() async {
      try {
        final response = await _dio.get<ResponseBody>(
          ApiPaths.syncEvents,
          queryParameters: {'exclude_device': ?excludeDeviceId},
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: Duration.zero,
            headers: {'Accept': 'text/event-stream'},
          ),
          cancelToken: cancelToken,
        );
        String? event;
        final data = StringBuffer();
        await for (final line
            in response.data!.stream
                .cast<List<int>>()
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (line.isEmpty) {
            if (event == 'change' && data.isNotEmpty) {
              final seq = (jsonDecode(data.toString()) as Map)['seq'];
              if (seq is int) controller.add(seq);
            }
            event = null;
            data.clear();
          } else if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            data.write(line.substring(5).trim());
          }
          // Comments (`: ping`) and `retry:` are ignored.
        }
      } on DioException catch (e, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(mapDioException(e, stackTrace));
        }
      } on Object catch (e, stackTrace) {
        if (!controller.isClosed) controller.addError(e, stackTrace);
      } finally {
        await controller.close();
      }
    }

    controller.onListen = () => unawaited(run());
    return controller.stream;
  }

  /// Opens a ranged download starting at [offset]. The caller drains
  /// [ContentDownload.stream]; the response's ETag is the document's sha256.
  Future<Result<ContentDownload>> downloadContent(
    String documentId, {
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<ResponseBody>(
        ApiPaths.documentContent(documentId),
        options: Options(
          responseType: ResponseType.stream,
          headers: {if (offset > 0) 'Range': 'bytes=$offset-'},
          receiveTimeout: Duration.zero,
          // 206 for a partial response, 200 when the server ignored Range.
          validateStatus: (s) => s == 200 || s == 206,
        ),
        cancelToken: cancelToken,
      );
      final headers = response.headers;
      final contentRange = headers.value('content-range');
      final total = contentRange == null
          ? int.tryParse(headers.value('content-length') ?? '')
          : int.tryParse(contentRange.split('/').last);
      return Ok(
        ContentDownload(
          stream: response.data!.stream,
          etag: (headers.value('etag') ?? '').replaceAll('"', ''),
          startsAt: response.statusCode == 206 ? offset : 0,
          totalBytes: total,
        ),
      );
    } on DioException catch (e, stackTrace) {
      return Err(mapDioException(e, stackTrace));
    }
  }

  Future<Result<MeResponse>> me() => _run(
    () => _dio.get<Map<String, Object?>>(ApiPaths.authMe),
    MeResponse.fromJson,
  );

  Future<Result<T>> _run<T, R>(
    Future<Response<R>> Function() call,
    T Function(R data) parse,
  ) async {
    try {
      final response = await call();
      return Ok(parse(response.data as R));
    } on DioException catch (e, stackTrace) {
      return Err(mapDioException(e, stackTrace));
    } on Object catch (e, stackTrace) {
      return Err(
        UnexpectedFailure('Bad response: $e', cause: e, stackTrace: stackTrace),
      );
    }
  }

  /// Converts a [DioException] into the domain [Failure] hierarchy.
  static Failure mapDioException(DioException e, [StackTrace? stackTrace]) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(
          'Cannot reach the server',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.cancel:
        return const CancelledFailure();
      case DioExceptionType.badCertificate:
        return NetworkFailure(
          'Untrusted server certificate',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final apiError = _parseError(e.response?.data);
        final message = apiError?.message ?? 'Request failed ($status)';
        if (status == 401) {
          return AuthFailure(message, cause: e, stackTrace: stackTrace);
        }
        return ServerFailure(
          message,
          statusCode: status,
          code: apiError == null ? null : _wireName(apiError.code),
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.unknown:
        return NetworkFailure(
          e.message ?? 'Network error',
          cause: e,
          stackTrace: stackTrace,
        );
    }
  }

  static ApiError? _parseError(Object? data) {
    if (data is! Map<String, Object?>) return null;
    try {
      return ApiError.fromEnvelope(data);
    } on Object {
      return null;
    }
  }

  static String _wireName(ApiErrorCode code) => code.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );
}

/// A streaming ranged read of a document's content.
class ContentDownload {
  const ContentDownload({
    required this.stream,
    required this.etag,
    required this.startsAt,
    this.totalBytes,
  });

  final Stream<Uint8List> stream;

  /// The document's sha256 as reported by the server.
  final String etag;

  /// Byte offset the stream starts at (0 when the server ignored `Range`).
  final int startsAt;
  final int? totalBytes;
}
