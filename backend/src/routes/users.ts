import { Hono } from 'hono';

import { findFriendship, getRelationship, toRelationship } from '../lib/friendship';
import { hashPassword, verifyPassword } from '../lib/password';
import { normalizeHandle, normalizeHandleQuery } from '../lib/handle';
import { FRIEND_IDS_SQL, PAGE_SIZE, POST_SELECT_SQL, type PostWithMetaRow, parseBefore, toPage, toPost } from '../lib/post';
import { findUserById, toPublicUser, toSelfUser } from '../lib/user';
import { isValidPassword, normalizeDisplayName } from '../lib/validation';
import { requireAuth } from '../middleware/auth';
import type { AppEnv, UserRow } from '../types';

export const userRoutes = new Hono<AppEnv>();

userRoutes.get('/me', requireAuth, async (c) => {
  const user = await findUserById(c.env.DB, c.get('userId'));
  if (!user) return c.json({ error: 'user_not_found' }, 404);
  return c.json({ user: toSelfUser(user) });
});

// Updates any of displayName / handle that is present in the body.
userRoutes.patch('/me', requireAuth, async (c) => {
  const body = await c.req
    .json<{ displayName?: unknown; handle?: unknown }>()
    .catch(() => ({ displayName: undefined, handle: undefined }));

  const sets: string[] = [];
  const values: unknown[] = [];
  if (body.displayName !== undefined) {
    const displayName = normalizeDisplayName(body.displayName);
    if (!displayName) return c.json({ error: 'invalid_display_name' }, 400);
    sets.push('display_name = ?');
    values.push(displayName);
  }
  if (body.handle !== undefined) {
    const handle = normalizeHandle(body.handle);
    if (!handle) return c.json({ error: 'invalid_handle' }, 400);
    sets.push('handle = ?');
    values.push(handle);
  }
  if (sets.length === 0) return c.json({ error: 'nothing_to_update' }, 400);

  let user: UserRow | null;
  try {
    user = await c.env.DB.prepare(`UPDATE users SET ${sets.join(', ')}, updated_at = ? WHERE id = ? RETURNING *`)
      .bind(...values, Date.now(), c.get('userId'))
      .first<UserRow>();
  } catch (e) {
    // The unique index on handle is the real check: it also catches two users grabbing the same handle at once.
    if (e instanceof Error && e.message.includes('users.handle')) return c.json({ error: 'handle_taken' }, 409);
    throw e;
  }
  if (!user) return c.json({ error: 'user_not_found' }, 404);
  return c.json({ user: toSelfUser(user) });
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

// Search by handle prefix ("@hk7" or "hk7") or by display name. Login usernames are never searched.
// Each result carries its relationship to the caller, so the app can show the right button at once.
userRoutes.get('/users/search', requireAuth, async (c) => {
  const meId = c.get('userId');
  const raw = c.req.query('q') ?? '';
  const handle = normalizeHandleQuery(raw);
  const name = raw.trim();
  if (name.length === 0) return c.json({ users: [] });

  // Escape LIKE wildcards so "_" and "%" typed by the user match literally.
  const escape = (value: string) => value.replace(/[\\%_]/g, (ch) => `\\${ch}`);
  const { results } = await c.env.DB.prepare(
    `SELECT * FROM users
     WHERE id <> ?3 AND (handle LIKE ?1 ESCAPE '\\' OR display_name LIKE ?2 ESCAPE '\\')
     ORDER BY handle = ?4 DESC, display_name COLLATE NOCASE
     LIMIT 20`,
  )
    .bind(`${escape(handle)}%`, `%${escape(name)}%`, meId, handle)
    .all<UserRow>();

  const users = await Promise.all(
    results.map(async (u) => ({
      ...toPublicUser(u),
      relationship: toRelationship(await findFriendship(c.env.DB, meId, u.id), meId),
    })),
  );
  return c.json({ users });
});

// Someone's profile page: who they are, how they relate to me, and a few counters.
userRoutes.get('/users/:id', requireAuth, async (c) => {
  const meId = c.get('userId');
  const user = await findUserById(c.env.DB, c.req.param('id'));
  if (!user) return c.json({ error: 'user_not_found' }, 404);

  const relationship = user.id === meId ? { status: 'self' as const } : await getRelationship(c.env.DB, meId, user.id);
  const counts = await c.env.DB.prepare(
    `SELECT (SELECT COUNT(*) FROM (${FRIEND_IDS_SQL})) AS friend_count,
            (SELECT COUNT(*) FROM posts WHERE author_id = ?1) AS post_count`,
  )
    .bind(user.id)
    .first<{ friend_count: number; post_count: number }>();

  return c.json({
    user: toPublicUser(user),
    relationship,
    friendCount: counts?.friend_count ?? 0,
    postCount: counts?.post_count ?? 0,
  });
});

// Only the user themselves and their friends may read their posts.
userRoutes.get('/users/:id/posts', requireAuth, async (c) => {
  const meId = c.get('userId');
  const authorId = c.req.param('id');
  if (authorId !== meId) {
    const relationship = await getRelationship(c.env.DB, meId, authorId);
    if (relationship.status !== 'friends') return c.json({ error: 'not_friends' }, 403);
  }

  const { results } = await c.env.DB.prepare(
    `${POST_SELECT_SQL}
     WHERE p.author_id = ?2 AND (?3 IS NULL OR p.created_at < ?3)
     ORDER BY p.created_at DESC
     LIMIT ${PAGE_SIZE}`,
  )
    .bind(meId, authorId, parseBefore(c.req.query('before')))
    .all<PostWithMetaRow>();
  return c.json(toPage(results.map(toPost)));
});

