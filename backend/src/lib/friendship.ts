import type { FriendshipRow } from '../types';

/** How `otherId` relates to `meId`, as seen by `meId`. */
export type Relationship =
  | { status: 'none' }
  | { status: 'friends'; requestId: string }
  | { status: 'outgoing' | 'incoming'; requestId: string };

export async function findFriendship(db: D1Database, a: string, b: string): Promise<FriendshipRow | null> {
  return db
    .prepare(
      `SELECT * FROM friendships
       WHERE (requester_id = ?1 AND addressee_id = ?2) OR (requester_id = ?2 AND addressee_id = ?1)`,
    )
    .bind(a, b)
    .first<FriendshipRow>();
}

export function toRelationship(row: FriendshipRow | null, meId: string): Relationship {
  if (!row) return { status: 'none' };
  if (row.status === 'accepted') return { status: 'friends', requestId: row.id };
  return { status: row.requester_id === meId ? 'outgoing' : 'incoming', requestId: row.id };
}

export async function getRelationship(db: D1Database, meId: string, otherId: string): Promise<Relationship> {
  return toRelationship(await findFriendship(db, meId, otherId), meId);
}

export async function areFriends(db: D1Database, a: string, b: string): Promise<boolean> {
  return (await findFriendship(db, a, b))?.status === 'accepted';
}
