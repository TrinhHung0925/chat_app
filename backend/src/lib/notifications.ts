import type { Context } from 'hono';

import type { AppEnv, Bindings, UserRow } from '../types';
import { sendPushToUser } from './fcm';
import { toPublicUser } from './user';

export type NotificationType = 'friend_request' | 'friend_accepted';

type NotificationWithActorRow = {
  id: string;
  type: NotificationType;
  ref_id: string | null;
  created_at: number;
  read_at: number | null;
} & Pick<UserRow, 'handle' | 'display_name'> & { actor_id: string; actor_created_at: number };

export const NOTIFICATION_SELECT_SQL = `
  SELECT n.id, n.type, n.ref_id, n.created_at, n.read_at, n.actor_id,
         u.handle, u.display_name, u.created_at AS actor_created_at
  FROM notifications n
  JOIN users u ON u.id = n.actor_id`;

export function toNotification(row: NotificationWithActorRow) {
  return {
    id: row.id,
    type: row.type,
    actor: toPublicUser({
      id: row.actor_id,
      handle: row.handle,
      display_name: row.display_name,
      created_at: row.actor_created_at,
    } as UserRow),
    refId: row.ref_id,
    createdAt: row.created_at,
    read: row.read_at !== null,
  };
}

export async function countUnread(db: D1Database, userId: string): Promise<number> {
  const row = await db
    .prepare('SELECT COUNT(*) AS n FROM notifications WHERE user_id = ?1 AND read_at IS NULL')
    .bind(userId)
    .first<{ n: number }>();
  return row?.n ?? 0;
}

function hub(env: Bindings, userId: string) {
  return env.USER_HUB.get(env.USER_HUB.idFromName(userId));
}

/**
 * Pushes an event to the user's open apps. Runs after the response is sent (waitUntil), so the
 * sender's request is never slowed down, and a failed push never fails the request: the
 * notification is already saved in D1 and shows up the next time the app loads the list.
 */
function push(c: Context<AppEnv>, userId: string, event: unknown) {
  c.executionCtx.waitUntil(
    hub(c.env, userId)
      .send(event)
      .catch((e) => console.warn('push to UserHub failed', userId, e)),
  );
}

export async function createNotification(
  c: Context<AppEnv>,
  input: { userId: string; actorId: string; type: NotificationType; refId?: string },
) {
  const db = c.env.DB;
  const id = crypto.randomUUID();
  await db
    .prepare(
      'INSERT INTO notifications (id, user_id, actor_id, type, ref_id, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)',
    )
    .bind(id, input.userId, input.actorId, input.type, input.refId ?? null, Date.now())
    .run();

  const [row, unreadCount] = await Promise.all([
    db.prepare(`${NOTIFICATION_SELECT_SQL} WHERE n.id = ?1`).bind(id).first<NotificationWithActorRow>(),
    countUnread(db, input.userId),
  ]);
  push(c, input.userId, { event: 'notification', notification: toNotification(row!), unreadCount });

  // Thêm một thông báo đẩy qua Firebase, để hiện lên cả khi app đã tắt hẳn.
  const name = row!.display_name;
  c.executionCtx.waitUntil(
    sendPushToUser(c.env, input.userId, {
      title: input.type === 'friend_request' ? 'Lời mời kết bạn' : 'Bạn mới',
      body:
        input.type === 'friend_request'
          ? `${name} đã gửi cho bạn lời mời kết bạn`
          : `${name} đã chấp nhận lời mời kết bạn`,
      data: { type: 'notification' },
    }),
  );
}

/** Removes the "X sent you a friend request" notification once the request is gone. */
export async function removeFriendRequestNotification(c: Context<AppEnv>, userId: string, requestId: string) {
  const { meta } = await c.env.DB.prepare(
    `DELETE FROM notifications WHERE user_id = ?1 AND type = 'friend_request' AND ref_id = ?2`,
  )
    .bind(userId, requestId)
    .run();
  if (meta.changes > 0) {
    push(c, userId, { event: 'unread_count', unreadCount: await countUnread(c.env.DB, userId) });
  }
}

export type { NotificationWithActorRow };
