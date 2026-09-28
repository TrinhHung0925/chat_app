import type { UserRow } from '../types';

export function toPublicUser(user: UserRow) {
  return {
    id: user.id,
    username: user.username,
    displayName: user.display_name,
    createdAt: user.created_at,
  };
}

export async function findUserById(db: D1Database, id: string): Promise<UserRow | null> {
  return db.prepare('SELECT * FROM users WHERE id = ?1').bind(id).first<UserRow>();
}
