import { sign, verify } from 'hono/jwt';

const ACCESS_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30;

export async function createAccessToken(userId: string, secret: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  return sign({ sub: userId, iat: now, exp: now + ACCESS_TOKEN_TTL_SECONDS }, secret, 'HS256');
}

export async function verifyAccessToken(token: string, secret: string): Promise<string> {
  const payload = await verify(token, secret, 'HS256');
  if (typeof payload.sub !== 'string') throw new Error('Token has no subject');
  return payload.sub;
}
