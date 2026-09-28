-- In-app notifications. Stored so a user who was offline still sees them next time,
-- and pushed live over WebSocket (see UserHub) to a user who has the app open.
CREATE TABLE notifications (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,  -- who receives it
  actor_id   TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,  -- who caused it
  type       TEXT NOT NULL CHECK (type IN ('friend_request', 'friend_accepted')),
  ref_id     TEXT,                                                    -- e.g. the friendship id
  created_at INTEGER NOT NULL,
  read_at    INTEGER
);

CREATE INDEX idx_notifications_user_created ON notifications (user_id, created_at DESC);
