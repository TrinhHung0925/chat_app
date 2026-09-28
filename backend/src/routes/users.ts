import { Hono } from 'hono';

import { requireAuth } from '../middleware/auth';
import type { AppEnv, UserRow } from '../types';

export function toPublicUser(user: UserRow) {
  return { id: user.id, email: user.email, name: user.name, avatarUrl: user.avatar_url };
}

export const userRoutes = new Hono<AppEnv>();

userRoutes.get('/me', requireAuth, async (c) => {
  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?1').bind(c.get('userId')).first<UserRow>();
  if (!user) return c.json({ error: 'user_not_found' }, 404);
  return c.json({ user: toPublicUser(user) });
});
