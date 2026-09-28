import { Hono } from 'hono';

import { verifyGoogleIdToken } from '../lib/google';
import { createAccessToken } from '../lib/token';
import type { AppEnv, UserRow } from '../types';
import { toPublicUser } from './users';

export const authRoutes = new Hono<AppEnv>();

authRoutes.post('/google', async (c) => {
  const body = await c.req.json<{ idToken?: string }>().catch(() => ({ idToken: undefined }));
  if (!body.idToken) return c.json({ error: 'missing_id_token' }, 400);

  const clientIds = c.env.GOOGLE_CLIENT_IDS.split(',').map((id) => id.trim()).filter(Boolean);
  let profile;
  try {
    profile = await verifyGoogleIdToken(body.idToken, clientIds);
  } catch (e) {
    console.warn('Google idToken rejected', e instanceof Error ? e.message : e);
    return c.json({ error: 'invalid_id_token' }, 401);
  }

  const now = Date.now();
  // Upsert keyed on google_sub: the first login creates the user, later logins refresh the profile.
  const user = await c.env.DB.prepare(
    `INSERT INTO users (id, google_sub, email, name, avatar_url, created_at, updated_at)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?6)
     ON CONFLICT (google_sub) DO UPDATE SET
       email = excluded.email,
       name = excluded.name,
       avatar_url = excluded.avatar_url,
       updated_at = excluded.updated_at
     RETURNING *`,
  )
    .bind(crypto.randomUUID(), profile.sub, profile.email, profile.name, profile.picture, now)
    .first<UserRow>();

  if (!user) return c.json({ error: 'user_upsert_failed' }, 500);

  const accessToken = await createAccessToken(user.id, c.env.JWT_SECRET);
  return c.json({ accessToken, user: toPublicUser(user) });
});
