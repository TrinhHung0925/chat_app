-- Users log in with a private `username`. Other users only ever see `display_name` and `handle`.
CREATE TABLE users (
  id            TEXT PRIMARY KEY,
  username      TEXT NOT NULL UNIQUE,
  -- Public code for search and friending (like @handle on TikTok/Instagram).
  -- Generated at registration; the user may change it as long as nobody else has it.
  handle        TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  display_name  TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

-- One row per pair of users. A pending row is a friend request from requester to addressee;
-- an accepted row means they are friends. Declining, cancelling or unfriending deletes the row.
CREATE TABLE friendships (
  id           TEXT PRIMARY KEY,
  requester_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  addressee_id TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  status       TEXT NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at   INTEGER NOT NULL,
  responded_at INTEGER,
  CHECK (requester_id <> addressee_id)
);

-- At most one row per pair regardless of direction: once A has asked B, B cannot open a second
-- row asking A. min()/max() put the two ids in a fixed order before the uniqueness check.
CREATE UNIQUE INDEX idx_friendships_pair
  ON friendships (min(requester_id, addressee_id), max(requester_id, addressee_id));

-- "Requests sent to me" and "my friends" look rows up from either side.
CREATE INDEX idx_friendships_addressee ON friendships (addressee_id, status);
CREATE INDEX idx_friendships_requester ON friendships (requester_id, status);
