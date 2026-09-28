import { Hono } from 'hono';

import {
  FRIEND_IDS_SQL,
  PAGE_SIZE,
  POST_SELECT_SQL,
  type PostWithMetaRow,
  findVisiblePost,
  parseBefore,
  toPage,
  toPost,
} from '../lib/post';
import { COMMENT_MAX_LENGTH, POST_MAX_LENGTH, normalizeText } from '../lib/validation';
import { requireAuth } from '../middleware/auth';
import type { AppEnv, CommentRow, UserRow } from '../types';

export const postRoutes = new Hono<AppEnv>();

postRoutes.use('*', requireAuth);

async function readContent(c: { req: { json: <T>() => Promise<T> } }, maxLength: number) {
  const body = await c.req.json<{ content?: unknown }>().catch(() => ({ content: undefined }));
  return normalizeText(body.content, maxLength);
}

postRoutes.post('/', async (c) => {
  const content = await readContent(c, POST_MAX_LENGTH);
  if (!content) return c.json({ error: 'invalid_content' }, 400);

  const meId = c.get('userId');
  const now = Date.now();
  const id = crypto.randomUUID();
  await c.env.DB.prepare('INSERT INTO posts (id, author_id, content, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?4)')
    .bind(id, meId, content, now)
    .run();

  const post = await findVisiblePost(c.env.DB, id, meId);
  return c.json({ post: toPost(post!) }, 201);
});

// My posts plus my friends' posts, newest first.
postRoutes.get('/feed', async (c) => {
  const meId = c.get('userId');
  const { results } = await c.env.DB.prepare(
    `${POST_SELECT_SQL}
     WHERE (p.author_id = ?1 OR p.author_id IN (${FRIEND_IDS_SQL}))
       AND (?2 IS NULL OR p.created_at < ?2)
     ORDER BY p.created_at DESC
     LIMIT ${PAGE_SIZE}`,
  )
    .bind(meId, parseBefore(c.req.query('before')))
    .all<PostWithMetaRow>();
  return c.json(toPage(results.map(toPost)));
});

postRoutes.get('/:id', async (c) => {
  const post = await findVisiblePost(c.env.DB, c.req.param('id'), c.get('userId'));
  if (!post) return c.json({ error: 'post_not_found' }, 404);
  return c.json({ post: toPost(post) });
});

postRoutes.patch('/:id', async (c) => {
  const content = await readContent(c, POST_MAX_LENGTH);
  if (!content) return c.json({ error: 'invalid_content' }, 400);

  const meId = c.get('userId');
  // `author_id = ?` in the WHERE clause is the permission check: other users' posts match no row.
  const updated = await c.env.DB.prepare(
    'UPDATE posts SET content = ?1, updated_at = ?2 WHERE id = ?3 AND author_id = ?4 RETURNING id',
  )
    .bind(content, Date.now(), c.req.param('id'), meId)
    .first<{ id: string }>();
  if (!updated) return c.json({ error: 'post_not_found' }, 404);

  const post = await findVisiblePost(c.env.DB, updated.id, meId);
  return c.json({ post: toPost(post!) });
});

// Likes and comments go away with the post through ON DELETE CASCADE.
postRoutes.delete('/:id', async (c) => {
  const { meta } = await c.env.DB.prepare('DELETE FROM posts WHERE id = ?1 AND author_id = ?2')
    .bind(c.req.param('id'), c.get('userId'))
    .run();
  if (meta.changes === 0) return c.json({ error: 'post_not_found' }, 404);
  return c.json({ ok: true });
});

// PUT/DELETE make like and unlike idempotent: tapping twice never double-counts.
postRoutes.put('/:id/like', async (c) => {
  const meId = c.get('userId');
  const post = await findVisiblePost(c.env.DB, c.req.param('id'), meId);
  if (!post) return c.json({ error: 'post_not_found' }, 404);

  await c.env.DB.prepare('INSERT INTO post_likes (post_id, user_id, created_at) VALUES (?1, ?2, ?3) ON CONFLICT DO NOTHING')
    .bind(post.id, meId, Date.now())
    .run();
  const updated = await findVisiblePost(c.env.DB, post.id, meId);
  return c.json({ post: toPost(updated!) });
});

postRoutes.delete('/:id/like', async (c) => {
  const meId = c.get('userId');
  const post = await findVisiblePost(c.env.DB, c.req.param('id'), meId);
  if (!post) return c.json({ error: 'post_not_found' }, 404);

  await c.env.DB.prepare('DELETE FROM post_likes WHERE post_id = ?1 AND user_id = ?2').bind(post.id, meId).run();
  const updated = await findVisiblePost(c.env.DB, post.id, meId);
  return c.json({ post: toPost(updated!) });
});

type CommentWithAuthorRow = CommentRow & Pick<UserRow, 'handle' | 'display_name'> & { author_created_at: number };

function toComment(row: CommentWithAuthorRow) {
  return {
    id: row.id,
    postId: row.post_id,
    author: { id: row.author_id, handle: row.handle, displayName: row.display_name, createdAt: row.author_created_at },
    content: row.content,
    createdAt: row.created_at,
  };
}

const COMMENT_SELECT_SQL = `
  SELECT c.*, u.handle, u.display_name, u.created_at AS author_created_at
  FROM post_comments c
  JOIN users u ON u.id = c.author_id`;

// Oldest first, like a conversation. Capped at 200 to keep this simple.
postRoutes.get('/:id/comments', async (c) => {
  const post = await findVisiblePost(c.env.DB, c.req.param('id'), c.get('userId'));
  if (!post) return c.json({ error: 'post_not_found' }, 404);

  const { results } = await c.env.DB.prepare(`${COMMENT_SELECT_SQL} WHERE c.post_id = ?1 ORDER BY c.created_at LIMIT 200`)
    .bind(post.id)
    .all<CommentWithAuthorRow>();
  return c.json({ comments: results.map(toComment) });
});

postRoutes.post('/:id/comments', async (c) => {
  const content = await readContent(c, COMMENT_MAX_LENGTH);
  if (!content) return c.json({ error: 'invalid_content' }, 400);

  const meId = c.get('userId');
  const post = await findVisiblePost(c.env.DB, c.req.param('id'), meId);
  if (!post) return c.json({ error: 'post_not_found' }, 404);

  const id = crypto.randomUUID();
  await c.env.DB.prepare('INSERT INTO post_comments (id, post_id, author_id, content, created_at) VALUES (?1, ?2, ?3, ?4, ?5)')
    .bind(id, post.id, meId, content, Date.now())
    .run();
  const comment = await c.env.DB.prepare(`${COMMENT_SELECT_SQL} WHERE c.id = ?1`).bind(id).first<CommentWithAuthorRow>();
  return c.json({ comment: toComment(comment!) }, 201);
});

// The comment's author or the post's author may delete a comment.
postRoutes.delete('/:id/comments/:commentId', async (c) => {
  const { meta } = await c.env.DB.prepare(
    `DELETE FROM post_comments
     WHERE id = ?1 AND post_id = ?2
       AND (author_id = ?3 OR post_id IN (SELECT id FROM posts WHERE author_id = ?3))`,
  )
    .bind(c.req.param('commentId'), c.req.param('id'), c.get('userId'))
    .run();
  if (meta.changes === 0) return c.json({ error: 'comment_not_found' }, 404);
  return c.json({ ok: true });
});

