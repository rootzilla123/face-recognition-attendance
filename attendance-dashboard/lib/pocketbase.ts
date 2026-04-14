import PocketBase from 'pocketbase';

const PB_URL = process.env.NEXT_PUBLIC_PB_URL ?? 'http://localhost:8090';

export const pb = new PocketBase(PB_URL);

// Restore session on load
if (typeof window !== 'undefined') {
  const token = localStorage.getItem('pb_token');
  const user = localStorage.getItem('pb_user');
  if (token && user) {
    try { pb.authStore.save(token, JSON.parse(user)); } catch {}
  }
}

// Keep localStorage in sync
pb.authStore.onChange(() => {
  if (typeof window === 'undefined') return;
  if (pb.authStore.isValid) {
    localStorage.setItem('pb_token', pb.authStore.token);
    localStorage.setItem('pb_user', JSON.stringify(pb.authStore.model));
  } else {
    localStorage.removeItem('pb_token');
    localStorage.removeItem('pb_user');
  }
});

export type PBUser = {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'teacher' | 'student' | 'parent';
  profile_id?: string;
  phone?: string;
  avatar?: string;
  verified: boolean;
};
