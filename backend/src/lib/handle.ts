// No 0/o, 1/l/i, so a handle read out loud or typed from a screenshot is not ambiguous.
const ALPHABET = 'abcdefghjkmnpqrstuvwxyz23456789';
export const HANDLE_LENGTH = 8;

export function generateHandle(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(HANDLE_LENGTH));
  // 256 % 31 leaves a tiny bias toward the first letters; harmless for an identifier that is not a secret.
  return Array.from(bytes, (b) => ALPHABET[b % ALPHABET.length]).join('');
}

/** Accepts "@hk7q2m9x" or "HK7Q2M9X" and returns "hk7q2m9x". */
export function normalizeHandleQuery(value: string): string {
  return value.trim().replace(/^@/, '').toLowerCase();
}

// Rules for a handle the user picks: 3-24 chars of a-z, 0-9, "_" or ".", not starting or ending with ".".
const HANDLE_PATTERN = /^(?!\.)[a-z0-9_.]{3,24}(?<!\.)$/;

export function normalizeHandle(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const handle = normalizeHandleQuery(value);
  return HANDLE_PATTERN.test(handle) ? handle : null;
}
