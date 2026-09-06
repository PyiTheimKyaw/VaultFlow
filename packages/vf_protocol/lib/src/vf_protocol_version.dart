/// Package identifier, handy for wiring smoke tests.
const String vfProtocolPackageName = 'vf_protocol';

/// Bumped whenever a breaking change is made to the wire contract. The client
/// sends it as `X-VaultFlow-Protocol`; the server rejects unknown majors.
const int vfProtocolVersion = 1;

/// Default chunk size for uploads: the S3 multipart minimum part size.
const int vfDefaultChunkSize = 5 * 1024 * 1024;

/// Maximum number of ops in a single push request.
const int vfMaxPushOps = 100;

/// Maximum number of changes returned by a single pull page.
const int vfMaxChangesPageSize = 500;
