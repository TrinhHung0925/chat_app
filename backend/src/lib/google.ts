import { createRemoteJWKSet, jwtVerify } from 'jose';

// Google rotates its signing keys; jose caches the key set and refetches when a new `kid` appears.
const googleJwks = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));

export type GoogleProfile = {
  sub: string;
  email: string;
  name: string;
  picture: string | null;
};

export async function verifyGoogleIdToken(idToken: string, clientIds: string[]): Promise<GoogleProfile> {
  const { payload } = await jwtVerify(idToken, googleJwks, {
    issuer: ['https://accounts.google.com', 'accounts.google.com'],
    audience: clientIds,
  });

  if (typeof payload.sub !== 'string' || typeof payload.email !== 'string') {
    throw new Error('idToken is missing sub or email');
  }
  if (payload.email_verified !== true) {
    throw new Error('Google email is not verified');
  }

  return {
    sub: payload.sub,
    email: payload.email,
    name: typeof payload.name === 'string' ? payload.name : payload.email,
    picture: typeof payload.picture === 'string' ? payload.picture : null,
  };
}
