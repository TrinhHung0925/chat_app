import { Hono } from 'hono';

import { authRoutes } from './routes/auth';
import { requireAuth } from './middleware/auth';
import { chatRoutes } from './routes/chat';
import { friendRoutes } from './routes/friends';
import { notificationRoutes } from './routes/notifications';
import { postRoutes } from './routes/posts';
import { userRoutes } from './routes/users';
import type { AppEnv } from './types';

const app = new Hono<AppEnv>();

app.get('/health', (c) => c.json({ status: 'ok', time: new Date().toISOString() }));
app.route('/auth', authRoutes);
app.route('/friends', friendRoutes);
app.route('/posts', postRoutes);
app.route('/notifications', notificationRoutes);
app.route('/chat', chatRoutes);

// The app keeps one WebSocket open while it is in the foreground. The Worker checks the token,
// then hands the connection to the caller's own UserHub Durable Object, which keeps it.
app.get('/ws', requireAuth, async (c) => {
  if (c.req.header('Upgrade') !== 'websocket') return c.json({ error: 'expected_websocket' }, 426);
  const hub = c.env.USER_HUB.get(c.env.USER_HUB.idFromName(c.get('userId')));
  return hub.fetch(c.req.raw);
});
app.route('/', userRoutes);

app.onError((err, c) => {
  console.error(err);
  return c.json({ error: 'internal_error' }, 500);
});

export { ChatRoom } from './chat_room';
export { UserHub } from './hub';

export default app;
