-- Text-only posts. Who may read a post is not stored here: it is checked when reading
-- (the author, or someone with an accepted friendship with the author).
CREATE TABLE posts (
  id         TEXT PRIMARY KEY,
  author_id  TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- "Posts by this user, newest first" (profile page) and the feed both walk this index.
CREATE INDEX idx_posts_author_created ON posts (author_id, created_at DESC);

-- The composite primary key makes "one like per user per post" a database rule.
CREATE TABLE post_likes (
  post_id    TEXT NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE post_comments (
  id         TEXT PRIMARY KEY,
  post_id    TEXT NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
  author_id  TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_post_comments_post_created ON post_comments (post_id, created_at);
