import type { ChatRoom } from './chat_room';
import type { UserHub } from './hub';

export type Bindings = {
  DB: D1Database;
  JWT_SECRET: string;
  USER_HUB: DurableObjectNamespace<UserHub>;
  CHAT_ROOM: DurableObjectNamespace<ChatRoom>;
};

export type Variables = {
  userId: string;
};

export type AppEnv = { Bindings: Bindings; Variables: Variables };

export type UserRow = {
  id: string;
  username: string;
  handle: string;
  password_hash: string;
  display_name: string;
  created_at: number;
  updated_at: number;
};

export type FriendshipRow = {
  id: string;
  requester_id: string;
  addressee_id: string;
  status: 'pending' | 'accepted';
  created_at: number;
  responded_at: number | null;
};

export type PostRow = {
  id: string;
  author_id: string;
  content: string;
  created_at: number;
  updated_at: number;
};

export type CommentRow = {
  id: string;
  post_id: string;
  author_id: string;
  content: string;
  created_at: number;
};
