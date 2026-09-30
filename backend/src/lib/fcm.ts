import type { Bindings } from '../types';

/**
 * Gửi thông báo đẩy (push) qua Firebase Cloud Messaging (FCM HTTP v1).
 *
 * Đường đi: Worker → FCM → (Android: thẳng tới máy) / (iOS: FCM chuyển tiếp qua APNs của Apple).
 * Worker không gọi thẳng APNs được vì APNs bắt buộc HTTP/2, còn `fetch` của Worker thì không.
 *
 * Để gọi FCM cần một "access token" của Google. Cách lấy:
 *  1. Tự ký một JWT bằng private key của service account (secret FCM_SERVICE_ACCOUNT).
 *  2. Gửi JWT đó cho Google để đổi lấy access token (sống 1 giờ).
 */

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

export type PushMessage = {
  title: string;
  body: string;
  // Dữ liệu kèm theo để app biết bấm vào thông báo thì mở màn nào. FCM chỉ nhận giá trị là chuỗi.
  data?: Record<string, string>;
  // Gom các thông báo cùng một cuộc trò chuyện thành một nhóm trên iOS.
  threadId?: string;
};

// Giữ access token trong bộ nhớ để không phải xin lại cho mỗi lần gửi.
// Mỗi isolate của Worker có bản riêng; hết hạn thì xin lại, không sao.
let cached: { token: string; expiresAt: number } | undefined;

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : new Uint8Array(input);
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

// Đổi private key dạng PEM ("-----BEGIN PRIVATE KEY-----...") thành CryptoKey để ký RS256.
function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(body), (ch) => ch.charCodeAt(0));
  return crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  // Còn hơn 1 phút mới hết hạn thì dùng tiếp.
  if (cached && cached.expiresAt - 60_000 > Date.now()) return cached.token;

  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const key = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`));
  const jwt = `${header}.${claims}.${base64url(signature)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwt }),
  });
  if (!res.ok) throw new Error(`Google OAuth ${res.status}: ${await res.text()}`);
  const { access_token, expires_in } = (await res.json()) as { access_token: string; expires_in: number };
  cached = { token: access_token, expiresAt: Date.now() + expires_in * 1000 };
  return access_token;
}

/**
 * Gửi [message] tới mọi máy của người dùng [userId]. Không bao giờ ném lỗi ra ngoài: push hỏng
 * thì người nhận vẫn thấy dữ liệu khi mở app, nên chỉ ghi log.
 */
export async function sendPushToUser(env: Bindings, userId: string, message: PushMessage): Promise<void> {
  // Chưa cài secret (ví dụ lúc chạy local) thì bỏ qua, không làm hỏng việc khác.
  if (!env.FCM_SERVICE_ACCOUNT) return;

  try {
    const { results: devices } = await env.DB.prepare('SELECT token FROM devices WHERE user_id = ?1')
      .bind(userId)
      .all<{ token: string }>();
    if (devices.length === 0) return;

    const sa = JSON.parse(env.FCM_SERVICE_ACCOUNT) as ServiceAccount;
    const accessToken = await getAccessToken(sa);
    const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    await Promise.all(
      devices.map(async ({ token }) => {
        const res = await fetch(url, {
          method: 'POST',
          headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: message.title, body: message.body },
              data: message.data,
              // Android: ưu tiên cao để máy đang ngủ cũng hiện ngay.
              android: { priority: 'high', notification: { sound: 'default' } },
              // iOS: có tiếng, và gom nhóm theo cuộc trò chuyện.
              apns: { payload: { aps: { sound: 'default', 'thread-id': message.threadId } } },
            },
          }),
        });
        if (res.ok) return;

        const text = await res.text();
        // Token không còn dùng được (app đã gỡ, token đổi...) thì xóa đi cho lần sau khỏi gửi.
        // Chỉ xóa khi lỗi nói rõ là do token, tránh xóa nhầm khi lỗi nằm ở nội dung mình gửi.
        if (res.status === 404 || (res.status === 400 && text.includes('registration token'))) {
          await env.DB.prepare('DELETE FROM devices WHERE token = ?1').bind(token).run();
          return;
        }
        console.warn('FCM send failed', res.status, text);
      }),
    );
  } catch (e) {
    console.warn('sendPushToUser failed', userId, e);
  }
}
