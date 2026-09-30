import { setPresence } from './lib/presence';
import type { Bindings } from './types';

/**
 * Việc chạy theo lịch (Cron Triggers). Cloudflare tự gọi hàm `scheduled` của Worker đúng giờ
 * đã khai trong wrangler.jsonc, không cần ai gửi request. Mỗi lịch có một chuỗi cron riêng,
 * nên dựa vào `controller.cron` để biết lần này là việc nào.
 *
 * Giờ trong cron là giờ UTC: "0 20 * * *" = 20:00 UTC = 3 giờ sáng giờ Việt Nam.
 */
export const CRON_CLEANUP = '0 20 * * *';
export const CRON_PRESENCE = '*/15 * * * *';

const DAY = 24 * 60 * 60 * 1000;

export async function scheduled(controller: ScheduledController, env: Bindings, ctx: ExecutionContext) {
  switch (controller.cron) {
    case CRON_CLEANUP:
      ctx.waitUntil(cleanup(env));
      break;
    case CRON_PRESENCE:
      ctx.waitUntil(fixStalePresence(env));
      break;
  }
}

/** 3 giờ sáng mỗi ngày: xóa dữ liệu cũ không còn dùng tới. */
async function cleanup(env: Bindings) {
  const now = Date.now();
  // batch: gửi nhiều câu lệnh trong một lần gọi D1, chạy như một giao dịch.
  const [readNotifications, oldNotifications, deadDevices] = await env.DB.batch([
    // Thông báo đã đọc quá 30 ngày.
    env.DB.prepare('DELETE FROM notifications WHERE read_at IS NOT NULL AND created_at < ?1').bind(now - 30 * DAY),
    // Thông báo chưa đọc nhưng đã quá 90 ngày: chắc chắn không ai xem nữa.
    env.DB.prepare('DELETE FROM notifications WHERE created_at < ?1').bind(now - 90 * DAY),
    // Máy không mở app suốt 60 ngày (mỗi lần mở app, token được đăng ký lại và updated_at mới lên):
    // có lẽ app đã bị gỡ, gửi push tới đó chỉ tốn công.
    env.DB.prepare('DELETE FROM devices WHERE updated_at < ?1').bind(now - 60 * DAY),
  ]);
  console.log('cleanup done', {
    readNotifications: readNotifications.meta.changes,
    oldNotifications: oldNotifications.meta.changes,
    deadDevices: deadDevices.meta.changes,
  });
}

/**
 * 15 phút một lần: sửa người bị kẹt "đang hoạt động".
 *
 * Bình thường UserHub tự ghi "rời đi" khi WebSocket cuối cùng đóng. Nhưng có lúc sự kiện đóng
 * không bao giờ tới (ví dụ server vừa deploy bản mới, mọi đường dây bị cắt ngang), khiến D1 vẫn
 * ghi is_online = 1. Ở đây hỏi thẳng UserHub của từng người đang "online" trong D1: không còn
 * đường dây nào thì chuyển về offline (và báo cho bạn bè như bình thường).
 */
async function fixStalePresence(env: Bindings) {
  const { results } = await env.DB.prepare('SELECT id FROM users WHERE is_online = 1').all<{ id: string }>();

  let fixed = 0;
  for (const { id } of results) {
    const online = await env.USER_HUB.get(env.USER_HUB.idFromName(id)).isOnline();
    if (!online) {
      await setPresence(env, id, false);
      fixed++;
    }
  }
  console.log('presence check done', { checked: results.length, fixed });
}
