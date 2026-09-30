import { Hono } from 'hono';

import { requireAuth } from '../middleware/auth';
import type { AppEnv } from '../types';

export const deviceRoutes = new Hono<AppEnv>();

deviceRoutes.use('*', requireAuth);

function readToken(body: unknown): string | undefined {
  const token = (body as { token?: unknown })?.token;
  return typeof token === 'string' && token.length > 0 && token.length <= 4096 ? token : undefined;
}

// App gọi sau khi đăng nhập (và mỗi khi Firebase cấp token mới): "máy này là của tôi".
deviceRoutes.post('/', async (c) => {
  const body = await c.req.json().catch(() => null);
  const token = readToken(body);
  const platform = (body as { platform?: unknown })?.platform;
  if (!token || (platform !== 'ios' && platform !== 'android')) return c.json({ error: 'invalid_device' }, 400);

  // Token đã có (ví dụ máy này trước đó đăng nhập tài khoản khác) thì chuyển sang người hiện tại,
  // để thông báo của người cũ không còn hiện trên máy này nữa.
  await c.env.DB.prepare(
    `INSERT INTO devices (token, user_id, platform, updated_at) VALUES (?1, ?2, ?3, ?4)
     ON CONFLICT (token) DO UPDATE SET user_id = excluded.user_id, platform = excluded.platform, updated_at = excluded.updated_at`,
  )
    .bind(token, c.get('userId'), platform, Date.now())
    .run();
  return c.json({ ok: true });
});

// App gọi lúc đăng xuất: máy này thôi nhận thông báo của tôi.
deviceRoutes.delete('/', async (c) => {
  const token = readToken(await c.req.json().catch(() => null));
  if (!token) return c.json({ error: 'invalid_device' }, 400);
  await c.env.DB.prepare('DELETE FROM devices WHERE token = ?1 AND user_id = ?2').bind(token, c.get('userId')).run();
  return c.json({ ok: true });
});
