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
    
    // Check if demo session exists
    const isDemoUser = localStorage.getItem('demo_user') === 'true';
    if (isDemoUser) {
      const demoRole = localStorage.getItem('demo_role') || 'student';
      const token = localStorage.getItem('auth_token');
      // Only restore if token exists
      if (token) {
        return {
          id: `demo-${demoRole}`,
          email: `${demoRole}@demo.local`,
          name: demoRole.charAt(0).toUpperCase() + demoRole.slice(1),
          role: demoRole as any,
          verified: true,
        };
      }
    }
    
    if (pb.authStore.isValid && pb.authStore.model) {
      return pb.authStore.model as unknown as PBUser;
    }
    return null;
  });
  const [isDemoUser, setIsDemoUser] = useState(() => {
    if (typeof window === 'undefined') return false;
    return localStorage.getItem('demo_user') === 'true';
  });
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
    try {
      // Fetch demo token from backend
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8001'}/api/v1/auth/demo-login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ role }),
      });

      if (!response.ok) {
        throw new Error(`Demo login failed: ${response.statusText}`);
      }

      const data = await response.json();
      
      // Store token in localStorage for API client to use
      localStorage.setItem('auth_token', data.access_token);
      
      // Create mock user object with response data
      const mockUser: PBUser = {
        id: data.user_id,
        email: `${role}@demo.local`,
        name: data.full_name,
        role: role,
        verified: true,
      };
      
      setUser(mockUser);
      setIsDemoUser(true);
      localStorage.setItem('demo_user', 'true');
      localStorage.setItem('demo_role', role);
    } catch (error) {
      console.error('Demo login error:', error);
      throw error;
    }
  };

  const logout = () => {
    pb.authStore.clear();
    localStorage.removeItem('api_token');
    localStorage.removeItem('auth_token');
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
