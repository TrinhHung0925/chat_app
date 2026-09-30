import { DurableObject } from 'cloudflare:workers';

import { setPresence } from './lib/presence';
import type { Bindings } from './types';

/**
 * One instance per user (addressed by user id). It holds that user's open WebSocket
 * connections, one per device with the app open, and forwards events to all of them.
 *
 * It uses the WebSocket Hibernation API (ctx.acceptWebSocket): while nothing is being sent,
 * the object is evicted from memory but the connections stay open, so idle users cost nothing.
 */
export class UserHub extends DurableObject<Bindings> {
  constructor(ctx: DurableObjectState, env: Bindings) {
    super(ctx, env);
    // Answered by the runtime itself, without waking the object up.
    ctx.setWebSocketAutoResponse(new WebSocketRequestResponsePair('ping', 'pong'));
  }

  async fetch(request: Request): Promise<Response> {
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('Expected a WebSocket upgrade', { status: 426 });
    }
    // Worker đã kiểm tra token và ghi id người dùng vào header này.
    const userId = request.headers.get('X-User-Id')!;
    // Trước khi nhận đường dây mới mà chưa có đường nào: người này vừa chuyển sang "đang hoạt động".
    const wasOffline = this.openSockets().length === 0;

    const { 0: client, 1: server } = new WebSocketPair();
    this.ctx.acceptWebSocket(server);
    // Gắn id vào đường dây, để lúc đường dây đóng (kể cả sau khi object đã ngủ) vẫn biết là của ai.
    server.serializeAttachment({ userId });

    if (wasOffline) this.ctx.waitUntil(setPresence(this.env, userId, true));
    return new Response(null, { status: 101, webSocket: client });
  }

  /** Called by the Worker (RPC). Sends one event to every open connection of this user. */
  async send(event: unknown): Promise<number> {
    const data = JSON.stringify(event);
    const sockets = this.ctx.getWebSockets();
    for (const ws of sockets) {
      try {
        ws.send(data);
      } catch {
        // A connection that is already closing; the runtime removes it on its own.
      }
    }
    return sockets.length;
  }

  async webSocketClose(ws: WebSocket, code: number, reason: string) {
    // 1005 ("không có mã") và 1006 ("đứt bất thường") là mã chỉ để BÁO, không được dùng để đóng:
    // gọi ws.close(1005) sẽ ném lỗi. Gặp hai mã này thì đóng bằng 1000 (bình thường).
    ws.close(code === 1005 || code === 1006 ? 1000 : code, reason);
    await this.onSocketGone(ws);
  }

  async webSocketError(ws: WebSocket) {
    await this.onSocketGone(ws);
  }

  /** Cron gọi (RPC) để kiểm tra lại: người này còn mở app trên máy nào không. */
  async isOnline(): Promise<boolean> {
    return this.openSockets().length > 0;
  }

  // Các đường dây còn mở thật sự (đường đang đóng dở thì không tính).
  private openSockets(except?: WebSocket) {
    return this.ctx.getWebSockets().filter((s) => s !== except && s.readyState === WebSocket.OPEN);
  }

  // Một đường dây vừa mất. Nếu đó là đường cuối cùng (người này đã đóng app trên mọi máy)
  // thì ghi "rời đi lúc này" và báo cho bạn bè.
  private async onSocketGone(ws: WebSocket) {
    const attachment = ws.deserializeAttachment() as { userId?: string } | null;
    if (!attachment?.userId) return; // đường dây cũ, mở từ trước khi có tính năng này
    if (this.openSockets(ws).length > 0) return;
    await setPresence(this.env, attachment.userId, false);
  }
}
