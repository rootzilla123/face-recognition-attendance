'use client';
import { createContext, useContext, useState, ReactNode, useEffect } from 'react';
import { pb, PBUser } from '@/lib/pocketbase';

interface AuthContextType {
  user: PBUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  demoLogin: (role: 'admin' | 'teacher' | 'student' | 'parent') => Promise<void>;
  logout: () => void;
  refreshUser: () => void;
  isDemoUser: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null, loading: false, isDemoUser: false,
  login: async () => {}, 
  demoLogin: async () => {},
  logout: () => {}, 
  refreshUser: () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<PBUser | null>(() => {
    if (typeof window === 'undefined') return null;
    if (pb.authStore.isValid && pb.authStore.model) {
      return pb.authStore.model as unknown as PBUser;
    }
    return null;
  });
  const [isDemoUser, setIsDemoUser] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(false);
  }, []);

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
    try {
      const auth = await pb.collection('users').authWithPassword(email, password);
      setUser(auth.record as unknown as PBUser);
      setIsDemoUser(false);
      localStorage.setItem('demo_user', 'false');
    } catch (error) {
      throw error;
    }
  };

  const demoLogin = async (role: 'admin' | 'teacher' | 'student' | 'parent') => {
    const mockUser: PBUser = {
      id: `demo-${role}`,
      email: `${role}@demo.local`,
      name: role.charAt(0).toUpperCase() + role.slice(1),
      role: role,
      created: new Date().toISOString(),
      updated: new Date().toISOString(),
    };
    
    setUser(mockUser);
    setIsDemoUser(true);
    localStorage.setItem('demo_user', 'true');
    localStorage.setItem('demo_role', role);
  };

  const logout = () => {
    pb.authStore.clear();
    localStorage.removeItem('api_token');
    localStorage.removeItem('demo_user');
    localStorage.removeItem('demo_role');
    setUser(null);
    setIsDemoUser(false);
    window.location.href = '/login';
  };

  const refreshUser = async () => {
    if (!pb.authStore.isValid) return;
    const record = await pb.collection('users').authRefresh();
    setUser(record.record as unknown as PBUser);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, demoLogin, logout, refreshUser, isDemoUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
