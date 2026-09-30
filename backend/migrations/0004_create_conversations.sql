-- Bảng tổng hợp để hiện DANH SÁCH CHAT. Tin nhắn thật nằm trong SQLite riêng của từng
-- ChatRoom (Durable Object); ở đây chỉ giữ "tin cuối" và "số chưa đọc" của mỗi cuộc trò chuyện,
-- vì muốn biết "tôi đang chat với ai" mà phải hỏi từng phòng một thì quá chậm.
CREATE TABLE conversations (
  id                TEXT PRIMARY KEY,           -- tên phòng, ví dụ "dm:<id nhỏ>:<id lớn>"
  type              TEXT NOT NULL CHECK (type IN ('direct')),
  last_message_text TEXT,
  last_sender_id    TEXT,
  last_message_at   INTEGER,
  created_at        INTEGER NOT NULL
);

-- Ai ở trong cuộc trò chuyện nào, và mỗi người còn bao nhiêu tin chưa đọc.
CREATE TABLE conversation_members (
  conversation_id TEXT NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
  user_id         TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  unread_count    INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (conversation_id, user_id)
);

-- "Danh sách chat của tôi" tìm theo user_id.
CREATE INDEX idx_conversation_members_user ON conversation_members (user_id);
