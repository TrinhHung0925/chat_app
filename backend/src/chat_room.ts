import { DurableObject } from 'cloudflare:workers';

import type { Bindings } from './types';

/**
 * Một phòng chat = một Durable Object.
 *
 * Mọi người đang mở phòng này đều giữ một WebSocket nối vào CHÍNH object này.
 * Ai gửi tin lên thì object phát tin đó cho tất cả mọi người trong phòng.
 *
 * Tin nhắn được lưu trong database SQLite riêng của chính object này (this.ctx.storage.sql),
 * nên mỗi phòng tự giữ lịch sử của mình.
 */

/** Thông tin gắn vào từng WebSocket để biết đường dây này là của ai. */
type Member = { userId: string; displayName: string; roomId: string };

/** App gửi lên. */
// App gửi lên 2 loại sự kiện, phân biệt bằng `type`:
//  - "message": tin nhắn thật, phát cho cả phòng.
//  - "typing": đang gõ (isTyping = true) hoặc đã thôi gõ (false). Chỉ báo cho người KHÁC,
//    không lưu lại, vì vài giây sau nó đã hết ý nghĩa.
type ClientEvent = { type: 'message'; text: string } | { type: 'typing'; isTyping: boolean };

export class ChatRoom extends DurableObject<Bindings> {
  constructor(ctx: DurableObjectState, env: Bindings) {
    super(ctx, env);
    // Server tự trả "pong" khi app gửi "ping", không cần đánh thức object.
    ctx.setWebSocketAutoResponse(new WebSocketRequestResponsePair('ping', 'pong'));

    // Tạo bảng lưu tin nhắn nếu chưa có. Mỗi phòng có database riêng, nên bảng này
    // chỉ chứa tin của đúng phòng này.
    ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS messages (
        id          TEXT PRIMARY KEY,
        sender_id   TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        text        TEXT NOT NULL,
        created_at  INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_messages_created ON messages (created_at);
    `);
  }

  /** Worker chuyển WebSocket của một người vào phòng qua hàm này. */
  async fetch(request: Request): Promise<Response> {
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('Expected a WebSocket upgrade', { status: 426 });
    }

    // Worker đã kiểm tra token và ghi sẵn người này là ai vào 2 header dưới đây.
    const member: Member = {
      userId: request.headers.get('X-User-Id')!,
      // Tên có dấu tiếng Việt nên được mã hóa khi đặt vào header; giải mã lại ở đây.
      displayName: decodeURIComponent(request.headers.get('X-User-Name')!),
      roomId: request.headers.get('X-Room-Id')!,
    };

    // Tạo một đường dây có 2 đầu: `client` trả về cho app, `server` phòng giữ lại.
    const { 0: client, 1: server } = new WebSocketPair();

    // Phòng "nhận giữ" đầu server. Dùng acceptWebSocket (Hibernation API) để khi phòng
    // im lặng, object được ngủ mà đường dây vẫn mở.
    this.ctx.acceptWebSocket(server);

    // Gắn thông tin người dùng vào chính đường dây. Object ngủ dậy vẫn đọc lại được,
    // vì thông tin này được lưu cùng WebSocket chứ không nằm trong biến của object.
    server.serializeAttachment(member);

    // Vừa vào phòng: gửi ngay lịch sử (50 tin gần nhất) cho riêng người này.
    server.send(JSON.stringify({ type: 'history', messages: this.recentMessages(50) }));

    return new Response(null, { status: 101, webSocket: client });
  }

  /** Chạy mỗi khi có người trong phòng gửi một tin lên. */
  async webSocketMessage(ws: WebSocket, raw: string | ArrayBuffer) {
    const sender = ws.deserializeAttachment() as Member;

    let event: ClientEvent;
    try {
      event = JSON.parse(typeof raw === 'string' ? raw : new TextDecoder().decode(raw));
    } catch {
      return; // không phải JSON thì bỏ qua
    }

    if (event.type === 'typing') {
      // Không gửi lại cho chính người đang gõ: bản thân mình không cần thấy "mình đang nhập".
      this.broadcast(
        {
          type: 'typing',
          userId: sender.userId,
          displayName: sender.displayName,
          isTyping: event.isTyping === true,
        },
        ws,
      );
      return;
    }

    if (event.type === 'message') {
      const text = typeof event.text === 'string' ? event.text.trim() : '';
      if (text.length === 0 || text.length > 2000) return;

      const message = {
        id: crypto.randomUUID(),
        senderId: sender.userId,
        senderName: sender.displayName,
        text,
        createdAt: Date.now(),
      };

      // 1. Lưu vào database của phòng TRƯỚC, để lỡ có sự cố thì tin cũng không mất.
      this.ctx.storage.sql.exec(
        'INSERT INTO messages (id, sender_id, sender_name, text, created_at) VALUES (?, ?, ?, ?, ?)',
        message.id,
        message.senderId,
        message.senderName,
        message.text,
        message.createdAt,
      );

      // 2. Rồi mới phát cho TẤT CẢ mọi người trong phòng, kể cả người gửi.
      // Người gửi nhận lại tin của chính mình nghĩa là "server đã nhận và đã lưu".
      this.broadcast({ type: 'message', message });

      // 3. Cập nhật danh sách chat (D1) và báo cho người không mở phòng.
      //    waitUntil: làm tiếp sau khi đã phát tin, không bắt người gửi phải chờ.
      this.ctx.waitUntil(this.updateConversation(sender, message));
    }
  }

  /**
   * Ghi "tin cuối" vào bảng conversations. Người nào KHÔNG đang mở phòng thì cộng 1 tin chưa đọc
   * và báo qua UserHub của họ, để tab Chat của họ tự cập nhật. Người đang mở phòng đã thấy tin
   * ngay trên màn chat rồi, nên không tính là chưa đọc.
   */
  private async updateConversation(
    sender: Member,
    message: { senderId: string; senderName: string; text: string; createdAt: number },
  ) {
    const online = new Set(this.ctx.getWebSockets().map((ws) => (ws.deserializeAttachment() as Member).userId));
    const db = this.env.DB;

    await db
      .prepare('UPDATE conversations SET last_message_text = ?1, last_sender_id = ?2, last_message_at = ?3 WHERE id = ?4')
      .bind(message.text, message.senderId, message.createdAt, sender.roomId)
      .run();

    const { results: members } = await db
      .prepare('SELECT user_id FROM conversation_members WHERE conversation_id = ?1')
      .bind(sender.roomId)
      .all<{ user_id: string }>();

    for (const { user_id } of members) {
      if (user_id === sender.userId) continue;
      if (!online.has(user_id)) {
        await db
          .prepare('UPDATE conversation_members SET unread_count = unread_count + 1 WHERE conversation_id = ?1 AND user_id = ?2')
          .bind(sender.roomId, user_id)
          .run();
      }
      // Báo cho mọi thiết bị đang mở app của người này (tab Chat tự tải lại).
      await this.env.USER_HUB.get(this.env.USER_HUB.idFromName(user_id))
        .send({ event: 'chat_message', conversationId: sender.roomId, senderName: message.senderName, text: message.text })
        .catch(() => {});
    }
  }

  /** [limit] tin gần nhất, xếp từ cũ tới mới để app hiện đúng thứ tự. */
  private recentMessages(limit: number) {
    const rows = this.ctx.storage.sql
      .exec<{ id: string; sender_id: string; sender_name: string; text: string; created_at: number }>(
        'SELECT * FROM messages ORDER BY created_at DESC LIMIT ?',
        limit,
      )
      .toArray();
    return rows.reverse().map((r) => ({
      id: r.id,
      senderId: r.sender_id,
      senderName: r.sender_name,
      text: r.text,
      createdAt: r.created_at,
    }));
  }

  async webSocketClose(ws: WebSocket, code: number, reason: string) {
    ws.close(code, reason);
  }

  /** Gửi một sự kiện cho mọi đường dây đang mở trong phòng, trừ [except] (nếu có). */
  private broadcast(event: unknown, except?: WebSocket) {
    const data = JSON.stringify(event);
    for (const ws of this.ctx.getWebSockets()) {
      if (ws === except) continue;
      try {
        ws.send(data);
      } catch {
        // đường dây đang đóng dở, bỏ qua
      }
    }
  }
}
