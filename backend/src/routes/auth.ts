import { Hono } from 'hono';

import { hashPassword, verifyPassword } from '../lib/password';
import { generateHandle } from '../lib/handle';
import { createAccessToken } from '../lib/token';
import { toSelfUser } from '../lib/user';
import { isValidPassword, normalizeDisplayName, normalizeUsername } from '../lib/validation';
import type { AppEnv, UserRow } from '../types';

export const authRoutes = new Hono<AppEnv>();

type Credentials = { username?: unknown; password?: unknown; displayName?: unknown };

authRoutes.post('/register', async (c) => {
  const body = await c.req.json<Credentials>().catch((): Credentials => ({}));
  const username = normalizeUsername(body.username);
  if (!username) return c.json({ error: 'invalid_username' }, 400);
  if (!isValidPassword(body.password)) return c.json({ error: 'invalid_password' }, 400);
  const displayName = normalizeDisplayName(body.displayName);
  if (!displayName) return c.json({ error: 'invalid_display_name' }, 400);

  const now = Date.now();
  const passwordHash = await hashPassword(body.password);

  // The login username stays private; other users only ever see displayName and handle.
  // ON CONFLICT (username) DO NOTHING + RETURNING gives no row when the username is taken,
  // without a race between "check if exists" and "insert".
  const insert = c.env.DB.prepare(
    `INSERT INTO users (id, username, handle, password_hash, display_name, created_at, updated_at)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?6)
     ON CONFLICT (username) DO NOTHING
     RETURNING *`,
  );

  let user: UserRow | null = null;
  // A handle collision (31^8 ≈ 850 billion codes) is very unlikely; retry a few times anyway.
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      user = await insert
        .bind(crypto.randomUUID(), username, generateHandle(), passwordHash, displayName, now)
        .first<UserRow>();
      break;
    } catch (e) {
      if (!(e instanceof Error && e.message.includes('users.handle'))) throw e;
    }
  }

  if (!user) return c.json({ error: 'username_taken' }, 409);

  const accessToken = await createAccessToken(user.id, c.env.JWT_SECRET);
  return c.json({ accessToken, user: toSelfUser(user) }, 201);
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
  return c.json({ accessToken, user: toSelfUser(user) });
});
