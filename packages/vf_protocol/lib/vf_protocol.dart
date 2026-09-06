/// Wire contract shared by client and server: DTOs, enums, error codes, paths.
///
/// Every request and response body exchanged between the Flutter app and the
/// dart_frog server is defined here, so the two sides cannot drift apart.
library;

export 'src/api_paths.dart';
export 'src/auth/auth_dtos.dart';
export 'src/entities/document_dto.dart';
export 'src/entities/folder_dto.dart';
export 'src/entities/note_dto.dart';
export 'src/enums/entity_type.dart';
export 'src/enums/sync_op.dart';
export 'src/enums/sync_op_status.dart';
export 'src/errors/api_error.dart';
export 'src/errors/api_error_code.dart';
export 'src/sync/changes_response.dart';
export 'src/sync/push_request.dart';
export 'src/sync/push_response.dart';
export 'src/transfer/upload_session_dtos.dart';
export 'src/vf_protocol_version.dart';
