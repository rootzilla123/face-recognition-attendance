'use client';
import { createContext, useContext, useState, ReactNode, useEffect } from 'react';
import { pb, PBUser } from '@/lib/pocketbase';

interface AuthContextType {
  user: PBUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => void;
}

const AuthContext = createContext<AuthContextType>({
  user: null, loading: false,
  login: async () => {}, logout: () => {}, refreshUser: () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<PBUser | null>(() => {
    if (typeof window === 'undefined') return null;
    if (pb.authStore.isValid && pb.authStore.model) {
      return pb.authStore.model as unknown as PBUser;
    }
    return null;
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    return pb.authStore.onChange(() => {
      if (pb.authStore.isValid && pb.authStore.model) {
        setUser(pb.authStore.model as unknown as PBUser);
      } else {
        setUser(null);
      }
    });
  }, []);

  const login = async (email: string, password: string) => {
    const auth = await pb.collection('users').authWithPassword(email, password);
    setUser(auth.record as unknown as PBUser);
  };

  const logout = () => {
    pb.authStore.clear();
    localStorage.removeItem('api_token');
    setUser(null);
    window.location.href = '/login';
  };

  const refreshUser = async () => {
    if (!pb.authStore.isValid) return;
    const record = await pb.collection('users').authRefresh();
    setUser(record.record as unknown as PBUser);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
