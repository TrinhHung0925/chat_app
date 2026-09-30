import { Hono } from 'hono';

import { areFriends } from '../lib/friendship';
import { findUserById } from '../lib/user';
import { requireAuth } from '../middleware/auth';
import type { AppEnv } from '../types';

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

  // Tìm (hoặc tự tạo) Durable Object của phòng này theo tên phòng.
  const room = c.env.CHAT_ROOM.get(c.env.CHAT_ROOM.idFromName(directRoomName(meId, otherId)));

  // Chuyển WebSocket vào phòng, kèm theo người này là ai. Mình tạo request mới và tự đặt header,
  // nên app không thể tự khai man X-User-Id: header app gửi lên (nếu có) bị ghi đè ở đây.
  const headers = new Headers(c.req.raw.headers);
  headers.set('X-User-Id', me.id);
  headers.set('X-User-Name', encodeURIComponent(me.display_name));
  return room.fetch(new Request(c.req.raw, { headers }));
});
