-- Mỗi máy đã cài app (và đã đăng nhập) có một "FCM token": địa chỉ để Firebase gửi thông báo
-- tới đúng máy đó, kể cả khi app đã bị tắt hẳn. Một người có thể có nhiều máy.
CREATE TABLE devices (
  token      TEXT PRIMARY KEY,                -- token do Firebase cấp cho máy
  user_id    TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  platform   TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  updated_at INTEGER NOT NULL
);

-- "Gửi thông báo cho người X" = tìm tất cả máy của X.
CREATE INDEX idx_devices_user ON devices (user_id);
