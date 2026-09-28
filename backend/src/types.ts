export type Bindings = {
  DB: D1Database;
  GOOGLE_CLIENT_IDS: string;
  JWT_SECRET: string;
};

export type Variables = {
  userId: string;
};

export type AppEnv = { Bindings: Bindings; Variables: Variables };

export type UserRow = {
  id: string;
  google_sub: string;
  email: string;
  name: string;
  avatar_url: string | null;
  created_at: number;
  updated_at: number;
};
