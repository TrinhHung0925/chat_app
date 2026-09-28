import { areFriends } from './friendship';

// Ids of everyone who has an accepted friendship with ?1.
export const FRIEND_IDS_SQL = `
  SELECT CASE WHEN requester_id = ?1 THEN addressee_id ELSE requester_id END
  FROM friendships
  WHERE status = 'accepted' AND (requester_id = ?1 OR addressee_id = ?1)`;

// A post with its author and counters, as seen by viewer ?1. Counting with subqueries keeps the
// schema simple; a busy app would store like_count / comment_count on posts instead.
export const POST_SELECT_SQL = `
  SELECT p.*,
         u.handle AS author_handle,
         u.display_name AS author_display_name,
         u.created_at AS author_created_at,
         (SELECT COUNT(*) FROM post_likes l WHERE l.post_id = p.id) AS like_count,
         (SELECT COUNT(*) FROM post_comments c WHERE c.post_id = p.id) AS comment_count,
         EXISTS (SELECT 1 FROM post_likes l WHERE l.post_id = p.id AND l.user_id = ?1) AS liked_by_me
  FROM posts p
  JOIN users u ON u.id = p.author_id`;

export const PAGE_SIZE = 20;

export type PostWithMetaRow = {
  id: string;
  author_id: string;
  content: string;
  created_at: number;
  updated_at: number;
  author_handle: string;
  author_display_name: string;
  author_created_at: number;
  like_count: number;
  comment_count: number;
  liked_by_me: number;
};

export function toPost(row: PostWithMetaRow) {
  return {
    id: row.id,
    author: {
      id: row.author_id,
      handle: row.author_handle,
      displayName: row.author_display_name,
      createdAt: row.author_created_at,
    },
    content: row.content,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    likeCount: row.like_count,
    commentCount: row.comment_count,
    likedByMe: row.liked_by_me === 1,
  };
}

/** Newest-first pages: pass the last item's createdAt as `before` to get the next page. */
export function toPage<T extends { createdAt: number }>(items: T[]) {
  return { items, nextBefore: items.length === PAGE_SIZE ? items[items.length - 1].createdAt : null };
}

export function parseBefore(value: string | undefined): number | null {
  const n = Number(value);
  return value && Number.isFinite(n) ? n : null;
}

/** The post if `viewerId` may read it (author or friend of the author), otherwise null. */
export async function findVisiblePost(db: D1Database, postId: string, viewerId: string) {
  const row = await db.prepare(`${POST_SELECT_SQL} WHERE p.id = ?2`).bind(viewerId, postId).first<PostWithMetaRow>();
  if (!row) return null;
  if (row.author_id !== viewerId && !(await areFriends(db, viewerId, row.author_id))) return null;
  return row;
}
