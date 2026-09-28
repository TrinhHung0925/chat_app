export type Bindings = {
  DB: D1Database;
  JWT_SECRET: string;
};

export type Variables = {
  userId: string;
};

export type AppEnv = { Bindings: Bindings; Variables: Variables };

export type UserRow = {
  id: string;
  username: string;
  password_hash: string;
  display_name: string;
  created_at: number;
  updated_at: number;
};
