import { DurableObject } from 'cloudflare:workers';

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
    const { 0: client, 1: server } = new WebSocketPair();
    this.ctx.acceptWebSocket(server);
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
    ws.close(code, reason);
  }
}
