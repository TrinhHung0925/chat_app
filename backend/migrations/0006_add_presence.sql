-- "Đang hoạt động" và "Hoạt động X phút trước".
-- is_online: 1 khi người này đang mở app (UserHub của họ còn ít nhất 1 WebSocket).
-- last_seen_at: lúc gần nhất họ mở app hoặc rời app. Chỉ bạn bè mới được xem hai cột này.
ALTER TABLE users ADD COLUMN is_online INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN last_seen_at INTEGER;
