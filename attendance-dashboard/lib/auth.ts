// Auth is now handled by PocketBase - this file kept for backward compat
import { pb } from './pocketbase';

export interface AuthUser {
  id: string;
  user_id: string;
  email: string;
  full_name: string;
  name: string;
  role: 'admin' | 'teacher' | 'student' | 'parent';
  access_token: string;
  profile_id?: string;
}

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return pb.authStore.isValid ? pb.authStore.token : null;
}

export function getUser(): AuthUser | null {
  if (typeof window === 'undefined') return null;
  if (!pb.authStore.isValid || !pb.authStore.model) return null;
  const m = pb.authStore.model;
  return {
    id: m.id, user_id: m.id,
    email: m.email, full_name: m.name, name: m.name,
    role: m.role, access_token: pb.authStore.token,
    profile_id: m.profile_id,
  };
}

export function clearAuth() {
  pb.authStore.clear();
}

export function isAuthenticated(): boolean {
  return pb.authStore.isValid;
}

// kept for legacy - no-op
export function saveAuth(_: any) {}
