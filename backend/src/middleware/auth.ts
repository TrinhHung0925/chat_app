import { createMiddleware } from 'hono/factory';

import { verifyAccessToken } from '../lib/token';
import type { AppEnv } from '../types';

export const requireAuth = createMiddleware<AppEnv>(async (c, next) => {
  const header = c.req.header('Authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7) : undefined;
  if (!token) return c.json({ error: 'missing_token' }, 401);

  try {
    c.set('userId', await verifyAccessToken(token, c.env.JWT_SECRET));
  } catch {
    return c.json({ error: 'invalid_token' }, 401);
  }
  await next();
});
