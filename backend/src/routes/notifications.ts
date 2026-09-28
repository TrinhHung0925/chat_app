import { Hono } from 'hono';

import {
  NOTIFICATION_SELECT_SQL,
  type NotificationWithActorRow,
  countUnread,
  toNotification,
} from '../lib/notifications';
import { requireAuth } from '../middleware/auth';
import type { AppEnv } from '../types';

export const notificationRoutes = new Hono<AppEnv>();

notificationRoutes.use('*', requireAuth);

notificationRoutes.get('/', async (c) => {
  const userId = c.get('userId');
  const [{ results }, unreadCount] = await Promise.all([
    c.env.DB.prepare(`${NOTIFICATION_SELECT_SQL} WHERE n.user_id = ?1 ORDER BY n.created_at DESC LIMIT 50`)
      .bind(userId)
      .all<NotificationWithActorRow>(),
    countUnread(c.env.DB, userId),
  ]);
  return c.json({ notifications: results.map(toNotification), unreadCount });
});

notificationRoutes.get('/unread-count', async (c) => {
  return c.json({ unreadCount: await countUnread(c.env.DB, c.get('userId')) });
});

notificationRoutes.post('/read-all', async (c) => {
  await c.env.DB.prepare('UPDATE notifications SET read_at = ?1 WHERE user_id = ?2 AND read_at IS NULL')
    .bind(Date.now(), c.get('userId'))
    .run();
  return c.json({ unreadCount: 0 });
});
