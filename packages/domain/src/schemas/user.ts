import { z } from 'zod';

// Ported verbatim from the zod schemas already living in
// apps/api/src/routes/{auth,users,coworkers}.js — those routes had their
// own copy each; this is now the single source both the API and the web
// app's forms can validate against.

export const registerSchema = z.object({
  fullName: z.string().min(1).max(200),
  email: z.string().email(),
  password: z.string().min(6).max(200),
  phoneNumber: z.string().max(30).optional(),
});
export type RegisterInput = z.infer<typeof registerSchema>;

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});
export type LoginInput = z.infer<typeof loginSchema>;

// apps/api/src/routes/users.js PATCH /me — the current user editing their
// own profile.
export const userUpdateSchema = z.object({
  fullName: z.string().min(1).max(200).optional(),
  phoneNumber: z.string().max(30).optional(),
  email: z.string().email().optional(),
  avatar: z.string().max(2000).optional(),
  password: z.string().min(6).max(200).optional(),
});
export type UserUpdateInput = z.infer<typeof userUpdateSchema>;

// apps/api/src/routes/coworkers.js POST / — an agent creating a coworker.
export const coworkerCreateSchema = z.object({
  fullName: z.string().min(1).max(200),
  email: z.string().email(),
  password: z.string().min(6).max(200),
  phoneNumber: z.string().max(30).optional(),
  avatar: z.string().max(2000).optional(),
});
export type CoworkerCreateInput = z.infer<typeof coworkerCreateSchema>;

// apps/api/src/routes/coworkers.js PATCH /:id — an agent editing a coworker.
export const coworkerUpdateSchema = z.object({
  fullName: z.string().min(1).max(200).optional(),
  email: z.string().email().optional(),
  phoneNumber: z.string().max(30).optional(),
  avatar: z.string().max(2000).optional(),
  password: z.string().min(6).max(200).optional(),
});
export type CoworkerUpdateInput = z.infer<typeof coworkerUpdateSchema>;
