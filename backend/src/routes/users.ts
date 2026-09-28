import { Hono } from 'hono';

import { hashPassword, verifyPassword } from '../lib/password';
import { findUserById, toPublicUser } from '../lib/user';
import { isValidPassword, normalizeDisplayName } from '../lib/validation';
import { requireAuth } from '../middleware/auth';
import type { AppEnv, UserRow } from '../types';

export const userRoutes = new Hono<AppEnv>();

userRoutes.get('/me', requireAuth, async (c) => {
  const user = await findUserById(c.env.DB, c.get('userId'));
  if (!user) return c.json({ error: 'user_not_found' }, 404);
  return c.json({ user: toPublicUser(user) });
});

userRoutes.patch('/me', requireAuth, async (c) => {
  const body = await c.req.json<{ displayName?: unknown }>().catch(() => ({ displayName: undefined }));
  const displayName = normalizeDisplayName(body.displayName);
  if (!displayName) return c.json({ error: 'invalid_display_name' }, 400);

  const user = await c.env.DB.prepare('UPDATE users SET display_name = ?1, updated_at = ?2 WHERE id = ?3 RETURNING *')
    .bind(displayName, Date.now(), c.get('userId'))
    .first<UserRow>();
  if (!user) return c.json({ error: 'user_not_found' }, 404);
  return c.json({ user: toPublicUser(user) });
});

userRoutes.put('/me/password', requireAuth, async (c) => {
  const body = await c.req
    .json<{ currentPassword?: unknown; newPassword?: unknown }>()
    .catch(() => ({ currentPassword: undefined, newPassword: undefined }));
  if (!isValidPassword(body.newPassword)) return c.json({ error: 'invalid_password' }, 400);

  const user = await findUserById(c.env.DB, c.get('userId'));
  if (!user) return c.json({ error: 'user_not_found' }, 404);

  const currentPassword = typeof body.currentPassword === 'string' ? body.currentPassword : '';
  if (!(await verifyPassword(currentPassword, user.password_hash))) {
    return c.json({ error: 'wrong_current_password' }, 400);
  }

  await c.env.DB.prepare('UPDATE users SET password_hash = ?1, updated_at = ?2 WHERE id = ?3')
    .bind(await hashPassword(body.newPassword), Date.now(), user.id)
    .run();
  return c.json({ ok: true });
});

userRoutes.get('/users', requireAuth, async (c) => {
  const { results } = await c.env.DB.prepare('SELECT * FROM users ORDER BY created_at DESC LIMIT 100').all<UserRow>();
  return c.json({ users: results.map(toPublicUser) });
});
