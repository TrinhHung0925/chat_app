import type { UserRow } from '../types';

/** What other users may see. The login username is private. */
export function toPublicUser(user: UserRow) {
  return {
    id: user.id,
    handle: user.handle,
    displayName: user.display_name,
    createdAt: user.created_at,
  };
}

/** What the signed-in user sees about themselves. */
export function toSelfUser(user: UserRow) {
  return { ...toPublicUser(user), username: user.username };
}

export async function findUserById(db: D1Database, id: string): Promise<UserRow | null> {
  return db.prepare('SELECT * FROM users WHERE id = ?1').bind(id).first<UserRow>();
}
