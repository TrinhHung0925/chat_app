import { Hono } from 'hono';

import { areFriends } from '../lib/friendship';
import { toPresence } from '../lib/presence';
import { findUserById, toPublicUser } from '../lib/user';
import { requireAuth } from '../middleware/auth';
import type { AppEnv, UserRow } from '../types';

export const chatRoutes = new Hono<AppEnv>();

chatRoutes.use('*', requireAuth);

/**
 * Tên phòng chat 1-1 giữa 2 người. Sắp xếp 2 id trước khi ghép, nên Bình mở phòng với Dũng
 * hay Dũng mở phòng với Bình đều ra CÙNG MỘT tên, tức là cùng một Durable Object.
 */
export function directRoomName(a: string, b: string): string {
  return a < b ? `dm:${a}:${b}` : `dm:${b}:${a}`;
}

// App mở WebSocket tới đây để vào phòng chat 1-1 với người có id là :userId.
chatRoutes.get('/direct/:userId/ws', async (c) => {
  if (c.req.header('Upgrade') !== 'websocket') return c.json({ error: 'expected_websocket' }, 426);

  const meId = c.get('userId');
  const otherId = c.req.param('userId');
  if (otherId === meId) return c.json({ error: 'cannot_chat_with_yourself' }, 400);

  // Chỉ bạn bè mới chat được với nhau, giống quy tắc xem bài viết.
  if (!(await areFriends(c.env.DB, meId, otherId))) return c.json({ error: 'not_friends' }, 403);

  const me = await findUserById(c.env.DB, meId);
  if (!me) return c.json({ error: 'user_not_found' }, 404);

  const roomId = directRoomName(meId, otherId);

  // Ghi cuộc trò chuyện vào bảng tổng hợp (lần đầu mở thì tạo mới, đã có thì bỏ qua),
  // và đặt số chưa đọc của mình về 0 vì mình đang mở phòng ra xem.
  await c.env.DB.batch([
    c.env.DB.prepare(
      `INSERT INTO conversations (id, type, created_at) VALUES (?1, 'direct', ?2) ON CONFLICT DO NOTHING`,
    ).bind(roomId, Date.now()),
    c.env.DB.prepare(
      `INSERT INTO conversation_members (conversation_id, user_id) VALUES (?1, ?2), (?1, ?3) ON CONFLICT DO NOTHING`,
    ).bind(roomId, meId, otherId),
    c.env.DB.prepare(
      'UPDATE conversation_members SET unread_count = 0 WHERE conversation_id = ?1 AND user_id = ?2',
    ).bind(roomId, meId),
  ]);

  // Tìm (hoặc tự tạo) Durable Object của phòng này theo tên phòng.
  const room = c.env.CHAT_ROOM.get(c.env.CHAT_ROOM.idFromName(roomId));

  // Chuyển WebSocket vào phòng, kèm theo người này là ai. Mình tạo request mới và tự đặt header,
  // nên app không thể tự khai man X-User-Id: header app gửi lên (nếu có) bị ghi đè ở đây.
  const headers = new Headers(c.req.raw.headers);
  headers.set('X-User-Id', me.id);
  headers.set('X-User-Name', encodeURIComponent(me.display_name));
  headers.set('X-Room-Id', roomId);
  return room.fetch(new Request(c.req.raw, { headers }));
});

type ConversationRow = {
  id: string;
  last_message_text: string | null;
  last_sender_id: string | null;
  last_message_at: number | null;
  unread_count: number;
} & Pick<UserRow, 'handle' | 'display_name'> & {
  other_id: string;
  other_created_at: number;
  is_online: number;
  last_seen_at: number | null;
};

// Danh sách chat của tôi: người đang chat cùng, tin cuối, số chưa đọc; mới nhất lên đầu.
// Chỉ lấy cuộc trò chuyện đã có ít nhất 1 tin (mở phòng rồi thoát mà không nhắn thì không hiện).
chatRoutes.get('/conversations', async (c) => {
  const { results } = await c.env.DB.prepare(
    `SELECT conv.id, conv.last_message_text, conv.last_sender_id, conv.last_message_at,
            mine.unread_count,
            u.id AS other_id, u.handle, u.display_name, u.created_at AS other_created_at,
            u.is_online, u.last_seen_at
     FROM conversation_members mine
     JOIN conversations conv ON conv.id = mine.conversation_id
     JOIN conversation_members other
       ON other.conversation_id = conv.id AND other.user_id <> mine.user_id
     JOIN users u ON u.id = other.user_id
     WHERE mine.user_id = ?1 AND conv.last_message_at IS NOT NULL
     ORDER BY conv.last_message_at DESC
     LIMIT 100`,
  )
    .bind(c.get('userId'))
    .all<ConversationRow>();

  // App vừa tải danh sách = tin mới đã về tới máy mình. Báo "đã nhận" cho những phòng
  // còn tin chưa đọc (người gửi sẽ thấy "Đã gửi" chuyển thành "Đã nhận").
  // Chạy sau khi đã trả kết quả (waitUntil), không bắt app phải chờ.
  const meId = c.get('userId');
  const pending = results.filter((r) => r.unread_count > 0);
  if (pending.length > 0) {
    c.executionCtx.waitUntil(
      Promise.all(
        pending.map((r) =>
          c.env.CHAT_ROOM.get(c.env.CHAT_ROOM.idFromName(r.id))
            .markDelivered(meId)
            .catch((e) => console.warn('markDelivered failed', r.id, e)),
        ),
      ),
    );
  }

  return c.json({
    conversations: results.map((r) => ({
      id: r.id,
      other: toPublicUser({ id: r.other_id, handle: r.handle, display_name: r.display_name, created_at: r.other_created_at } as UserRow),
      lastMessageText: r.last_message_text,
      lastSenderId: r.last_sender_id,
      lastMessageAt: r.last_message_at,
      unreadCount: r.unread_count,
      // Người kia có đang hoạt động không (chấm xanh trên avatar).
      presence: toPresence(r),
    })),
  });
});

// Trạng thái hoạt động của một người bạn, cho dòng "Đang hoạt động / Hoạt động X phút trước"
// trên màn chat. Không phải bạn bè thì không được xem.
chatRoutes.get('/direct/:userId/presence', async (c) => {
  const otherId = c.req.param('userId');
  if (!(await areFriends(c.env.DB, c.get('userId'), otherId))) return c.json({ error: 'not_friends' }, 403);
  const row = await c.env.DB.prepare('SELECT is_online, last_seen_at FROM users WHERE id = ?1')
    .bind(otherId)
    .first<{ is_online: number; last_seen_at: number | null }>();
  if (!row) return c.json({ error: 'user_not_found' }, 404);
  return c.json({ presence: toPresence(row) });
});
