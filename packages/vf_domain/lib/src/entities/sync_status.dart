/// Local sync state of an entity row.
enum SyncStatus {
  /// Local row matches the server version.
  synced,

  /// Local edits are queued in the outbox.
  pending,

  /// The last push was rejected with a version conflict; see `conflicts`.
  conflicted,
}

/// Whether a document's bytes are present on this device.
enum CacheState { none, partial, complete }
