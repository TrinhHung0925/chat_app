import { Hono } from 'hono';

import { hashPassword, verifyPassword } from '../lib/password';
import { createAccessToken } from '../lib/token';
import { toPublicUser } from '../lib/user';
import { isValidPassword, normalizeUsername } from '../lib/validation';
import type { AppEnv, UserRow } from '../types';

export const authRoutes = new Hono<AppEnv>();

type Credentials = { username?: unknown; password?: unknown };

authRoutes.post('/register', async (c) => {
  const body = await c.req.json<Credentials>().catch((): Credentials => ({}));
  const username = normalizeUsername(body.username);
  if (!username) return c.json({ error: 'invalid_username' }, 400);
  if (!isValidPassword(body.password)) return c.json({ error: 'invalid_password' }, 400);

  const now = Date.now();
  // The display name starts as the username; the user can change it on the profile screen.
  // ON CONFLICT DO NOTHING + RETURNING gives no row when the username is taken, without a race
  // between "check if exists" and "insert".
  const user = await c.env.DB.prepare(
    `INSERT INTO users (id, username, password_hash, display_name, created_at, updated_at)
     VALUES (?1, ?2, ?3, ?2, ?4, ?4)
     ON CONFLICT (username) DO NOTHING
     RETURNING *`,
  )
    .bind(crypto.randomUUID(), username, await hashPassword(body.password), now)
    .first<UserRow>();

  if (!user) return c.json({ error: 'username_taken' }, 409);

  const accessToken = await createAccessToken(user.id, c.env.JWT_SECRET);
  return c.json({ accessToken, user: toPublicUser(user) }, 201);
});

authRoutes.post('/login', async (c) => {
  const body = await c.req.json<Credentials>().catch((): Credentials => ({}));
  const username = normalizeUsername(body.username);
  const password = typeof body.password === 'string' ? body.password : '';

  const user = username
    ? await c.env.DB.prepare('SELECT * FROM users WHERE username = ?1').bind(username).first<UserRow>()
    : null;

  // Same error for "no such user" and "wrong password", so the API does not reveal which usernames exist.
  if (!user || !(await verifyPassword(password, user.password_hash))) {
    return c.json({ error: 'invalid_credentials' }, 401);
  }

  const accessToken = await createAccessToken(user.id, c.env.JWT_SECRET);
  return c.json({ accessToken, user: toPublicUser(user) });
});
