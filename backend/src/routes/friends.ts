import { Hono } from 'hono';

import { findFriendship, toRelationship } from '../lib/friendship';
import { toPublicUser } from '../lib/user';
import { requireAuth } from '../middleware/auth';
import type { AppEnv, FriendshipRow, UserRow } from '../types';

export const friendRoutes = new Hono<AppEnv>();

friendRoutes.use('*', requireAuth);

// Users joined with the friendship row that links them to `meId`, filtered by the given condition.
const OTHER_USER_SQL = `
  SELECT u.*, f.id AS request_id, f.created_at AS request_created_at, f.responded_at
  FROM friendships f
  JOIN users u ON u.id = CASE WHEN f.requester_id = ?1 THEN f.addressee_id ELSE f.requester_id END`;

type OtherUserRow = UserRow & { request_id: string; request_created_at: number; responded_at: number | null };

friendRoutes.get('/', async (c) => {
  const { results } = await c.env.DB.prepare(
    `${OTHER_USER_SQL}
     WHERE (f.requester_id = ?1 OR f.addressee_id = ?1) AND f.status = 'accepted'
     ORDER BY u.display_name COLLATE NOCASE`,
  )
    .bind(c.get('userId'))
    .all<OtherUserRow>();
  return c.json({ friends: results.map((r) => ({ ...toPublicUser(r), friendsSince: r.responded_at })) });
});

friendRoutes.get('/requests', async (c) => {
  const meId = c.get('userId');
  const [incoming, outgoing] = await c.env.DB.batch<OtherUserRow>([
    c.env.DB.prepare(
      `${OTHER_USER_SQL} WHERE f.addressee_id = ?1 AND f.status = 'pending' ORDER BY f.created_at DESC`,
    ).bind(meId),
    c.env.DB.prepare(
      `${OTHER_USER_SQL} WHERE f.requester_id = ?1 AND f.status = 'pending' ORDER BY f.created_at DESC`,
    ).bind(meId),
  ]);
  const toRequest = (r: OtherUserRow) => ({ id: r.request_id, user: toPublicUser(r), createdAt: r.request_created_at });
  return c.json({ incoming: incoming.results.map(toRequest), outgoing: outgoing.results.map(toRequest) });
});

friendRoutes.post('/requests', async (c) => {
  const meId = c.get('userId');
  // The app sends the id it got from search or a profile page.
  const body = await c.req.json<{ userId?: unknown }>().catch(() => ({ userId: undefined }));
  if (typeof body.userId !== 'string') return c.json({ error: 'invalid_user_id' }, 400);

  const target = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?1').bind(body.userId).first<UserRow>();
  if (!target) return c.json({ error: 'user_not_found' }, 404);
  if (target.id === meId) return c.json({ error: 'cannot_friend_yourself' }, 400);

  const existing = await findFriendship(c.env.DB, meId, target.id);
  if (existing?.status === 'accepted') return c.json({ error: 'already_friends' }, 409);
  if (existing?.requester_id === meId) return c.json({ error: 'request_already_sent' }, 409);

  const now = Date.now();
  if (existing) {
    // They already asked me: sending a request back means yes, so accept theirs.
    await c.env.DB.prepare(`UPDATE friendships SET status = 'accepted', responded_at = ?1 WHERE id = ?2`)
      .bind(now, existing.id)
      .run();
    return c.json({ relationship: { status: 'friends', requestId: existing.id }, user: toPublicUser(target) });
  }

  // The unique pair index still guards against two requests racing in at the same moment.
  const row = await c.env.DB.prepare(
    `INSERT INTO friendships (id, requester_id, addressee_id, status, created_at)
     VALUES (?1, ?2, ?3, 'pending', ?4)
     ON CONFLICT DO NOTHING
     RETURNING *`,
  )
    .bind(crypto.randomUUID(), meId, target.id, now)
    .first<FriendshipRow>();
  if (!row) return c.json({ error: 'request_already_exists' }, 409);

  return c.json({ relationship: toRelationship(row, meId), user: toPublicUser(target) }, 201);
});

async function findPendingRequest(db: D1Database, id: string): Promise<FriendshipRow | null> {
  return db.prepare(`SELECT * FROM friendships WHERE id = ?1 AND status = 'pending'`).bind(id).first<FriendshipRow>();
}

friendRoutes.post('/requests/:id/accept', async (c) => {
  const request = await findPendingRequest(c.env.DB, c.req.param('id'));
  if (!request || request.addressee_id !== c.get('userId')) return c.json({ error: 'request_not_found' }, 404);

  await c.env.DB.prepare(`UPDATE friendships SET status = 'accepted', responded_at = ?1 WHERE id = ?2`)
    .bind(Date.now(), request.id)
    .run();
  return c.json({ ok: true });
});

// The addressee declines, or the requester cancels; either way the request disappears.
friendRoutes.delete('/requests/:id', async (c) => {
  const meId = c.get('userId');
  const request = await findPendingRequest(c.env.DB, c.req.param('id'));
  if (!request || (request.addressee_id !== meId && request.requester_id !== meId)) {
    return c.json({ error: 'request_not_found' }, 404);
  }

  await c.env.DB.prepare('DELETE FROM friendships WHERE id = ?1').bind(request.id).run();
  return c.json({ ok: true });
});

friendRoutes.delete('/:userId', async (c) => {
  const friendship = await findFriendship(c.env.DB, c.get('userId'), c.req.param('userId'));
  if (friendship?.status !== 'accepted') return c.json({ error: 'not_friends' }, 404);

  await c.env.DB.prepare('DELETE FROM friendships WHERE id = ?1').bind(friendship.id).run();
  return c.json({ ok: true });
});
