-- Switch from Google sign-in to username + password.
-- The old users table only held test rows, so it is dropped instead of migrated.
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id            TEXT PRIMARY KEY,
  username      TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  display_name  TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
