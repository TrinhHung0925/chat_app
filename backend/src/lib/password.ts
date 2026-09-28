// Passwords are never stored. We store PBKDF2-SHA256(password, random salt) instead, so a leaked
// database does not reveal passwords, and equal passwords still produce different hashes.
// Stored format: pbkdf2$<iterations>$<salt base64>$<hash base64>

// 100k is the maximum PBKDF2 iteration count the Workers runtime allows.
const ITERATIONS = 100_000;
const SALT_BYTES = 16;
const HASH_BITS = 256;

const encoder = new TextEncoder();

function toBase64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}

function fromBase64(value: string): Uint8Array {
  return Uint8Array.from(atob(value), (ch) => ch.charCodeAt(0));
}

async function derive(password: string, salt: Uint8Array, iterations: number): Promise<Uint8Array> {
  const key = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', hash: 'SHA-256', salt, iterations }, key, HASH_BITS);
  return new Uint8Array(bits);
}

export async function hashPassword(password: string): Promise<string> {
  const salt = crypto.getRandomValues(new Uint8Array(SALT_BYTES));
  const hash = await derive(password, salt, ITERATIONS);
  return `pbkdf2$${ITERATIONS}$${toBase64(salt)}$${toBase64(hash)}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [scheme, iterations, salt, hash] = stored.split('$');
  if (scheme !== 'pbkdf2' || !iterations || !salt || !hash) return false;

  const expected = fromBase64(hash);
  const actual = await derive(password, fromBase64(salt), Number(iterations));
  // Constant-time comparison, so response timing does not leak how many bytes matched.
  return actual.byteLength === expected.byteLength && crypto.subtle.timingSafeEqual(actual, expected);
}
