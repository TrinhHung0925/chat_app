import { Hono } from 'hono';

import { authRoutes } from './routes/auth';
import { friendRoutes } from './routes/friends';
import { postRoutes } from './routes/posts';
import { userRoutes } from './routes/users';
import type { AppEnv } from './types';

const app = new Hono<AppEnv>();

app.get('/health', (c) => c.json({ status: 'ok', time: new Date().toISOString() }));
app.route('/auth', authRoutes);
app.route('/friends', friendRoutes);
app.route('/posts', postRoutes);
app.route('/', userRoutes);

app.onError((err, c) => {
  console.error(err);
  return c.json({ error: 'internal_error' }, 500);
});

export default app;
