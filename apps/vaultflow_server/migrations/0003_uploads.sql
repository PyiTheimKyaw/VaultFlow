-- Content-addressed blobs (one per user + sha256) and resumable upload
-- sessions. Parts are tracked server-side so a client can ask what it still
-- needs to send after a crash.

CREATE TABLE blobs (
  storage_key TEXT PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sha256      TEXT NOT NULL,
  size_bytes  BIGINT NOT NULL,
  ref_count   INTEGER NOT NULL DEFAULT 1,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, sha256)
);

CREATE TABLE upload_sessions (
  id              TEXT PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  document_id     TEXT NOT NULL,
  storage_key     TEXT NOT NULL,
  mime_type       TEXT NOT NULL,
  total_bytes     BIGINT NOT NULL,
  chunk_size      INTEGER NOT NULL,
  sha256_expected TEXT NOT NULL,
  received        JSONB NOT NULL DEFAULT '{}'::jsonb,   -- {"<index>": "<part sha256>"}
  state           TEXT NOT NULL DEFAULT 'active',
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_upload_sessions_user ON upload_sessions(user_id);
CREATE INDEX idx_upload_sessions_expires ON upload_sessions(expires_at);
