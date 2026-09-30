import { DurableObject } from 'cloudflare:workers';

import type { Bindings } from './types';

/**
 * Một phòng chat = một Durable Object.
 *
 * Mọi người đang mở phòng này đều giữ một WebSocket nối vào CHÍNH object này.
 * Ai gửi tin lên thì object phát tin đó cho tất cả mọi người trong phòng.
 *
 * Bước 2: chỉ nhận và phát tin, chưa lưu lại (bước 5 mới lưu).
 */

/** Thông tin gắn vào từng WebSocket để biết đường dây này là của ai. */
type Member = { userId: string; displayName: string };

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
    };

    // Tạo một đường dây có 2 đầu: `client` trả về cho app, `server` phòng giữ lại.
    const { 0: client, 1: server } = new WebSocketPair();

    // Phòng "nhận giữ" đầu server. Dùng acceptWebSocket (Hibernation API) để khi phòng
    // im lặng, object được ngủ mà đường dây vẫn mở.
    this.ctx.acceptWebSocket(server);

    // Gắn thông tin người dùng vào chính đường dây. Object ngủ dậy vẫn đọc lại được,
    // vì thông tin này được lưu cùng WebSocket chứ không nằm trong biến của object.
    server.serializeAttachment(member);

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

      // Phát cho TẤT CẢ mọi người trong phòng, kể cả người gửi.
      // Người gửi nhận lại tin của chính mình nghĩa là "server đã nhận, gửi thành công".
      this.broadcast({
        type: 'message',
        message: {
          id: crypto.randomUUID(),
          senderId: sender.userId,
          senderName: sender.displayName,
          text,
          createdAt: Date.now(),
        },
      });
    }
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
