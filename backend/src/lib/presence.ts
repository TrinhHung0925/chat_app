import type { Bindings } from '../types';

export type Presence = { online: boolean; lastSeenAt: number | null };

export function toPresence(row: { is_online: number; last_seen_at: number | null }): Presence {
  return { online: row.is_online === 1, lastSeenAt: row.last_seen_at };
}

/**
 * Ghi "đang hoạt động / vừa rời đi" của [userId] vào D1, rồi báo cho từng người bạn của họ
 * qua UserHub của người bạn đó. Bạn nào đang mở app sẽ thấy chấm xanh bật / tắt ngay.
 */
export async function setPresence(env: Bindings, userId: string, online: boolean): Promise<void> {
  const now = Date.now();
  await env.DB.prepare('UPDATE users SET is_online = ?1, last_seen_at = ?2 WHERE id = ?3')
    .bind(online ? 1 : 0, now, userId)
    .run();

  // Danh sách bạn bè của userId: mỗi dòng kết bạn, lấy "người còn lại".
  const { results } = await env.DB.prepare(
    `SELECT CASE WHEN requester_id = ?1 THEN addressee_id ELSE requester_id END AS friend_id
     FROM friendships
     WHERE status = 'accepted' AND (requester_id = ?1 OR addressee_id = ?1)`,
  )
    .bind(userId)
    .all<{ friend_id: string }>();

  const event = { event: 'presence', userId, online, lastSeenAt: now };
  await Promise.all(
    results.map(({ friend_id }) =>
      env.USER_HUB.get(env.USER_HUB.idFromName(friend_id))
        .send(event)
        .catch(() => {}),
    ),
  );
}
