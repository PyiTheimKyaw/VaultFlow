-- Synced entities, the append-only change feed, and idempotent push results.
-- Entity ids are client-generated UUID v7 strings; kept as TEXT so a
-- malformed id is rejected by the service, not by a cast error.

CREATE TABLE folders (
  id         TEXT PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id  TEXT,
  name       TEXT NOT NULL,
  version    INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_folders_user ON folders(user_id);

CREATE TABLE documents (
  id          TEXT PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  folder_id   TEXT,
  name        TEXT NOT NULL,
  mime_type   TEXT NOT NULL,
  size_bytes  BIGINT NOT NULL,
  sha256      TEXT NOT NULL,
  storage_key TEXT,
  version     INTEGER NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL,
  deleted_at  TIMESTAMPTZ
);
CREATE INDEX idx_documents_user ON documents(user_id);

CREATE TABLE notes (
  id         TEXT PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  folder_id  TEXT,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  version    INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_notes_user ON notes(user_id);

-- Every applied op appends one row; clients pull by (user_id, seq).
CREATE TABLE changes (
  seq         BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id   TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id   TEXT NOT NULL,
  op          TEXT NOT NULL,
  version     INTEGER NOT NULL,
  payload     JSONB NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_changes_user_seq ON changes(user_id, seq);

-- Result of each (device, client_op_id) so a retried push replays the same
-- answer instead of applying the op twice.
CREATE TABLE applied_ops (
  device_id    TEXT NOT NULL,
  client_op_id TEXT NOT NULL,
  result       JSONB NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (device_id, client_op_id)
);
