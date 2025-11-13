import { createContext, useContext, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import client from "../api/client";

export type UserRole = "member" | "librarian";

export interface User {
  id: number;
  name: string;
  email: string;
  role: UserRole;
}

interface AuthResponse {
  token: string;
  user: User;
}

interface AuthContextValue {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  signup: (name: string, email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    const storedToken = localStorage.getItem("authToken");
    const storedUser = localStorage.getItem("authUser");
    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
    }
  }, []);

  const persistAuth = (data: AuthResponse) => {
    localStorage.setItem("authToken", data.token);
    localStorage.setItem("authUser", JSON.stringify(data.user));
    setToken(data.token);
    setUser(data.user);
  };

  const login = async (email: string, password: string) => {
    const response = await client.post<AuthResponse>("/login", {
      user: { email, password },
    });

    persistAuth(response.data);
  };

  const signup = async (name: string, email: string, password: string) => {
    const response = await client.post<AuthResponse>("/signup", {
      user: { name, email, password, password_confirmation: password },
    });

    persistAuth(response.data);
  };

  const logout = () => {
    localStorage.removeItem("authToken");
    localStorage.removeItem("authUser");
    setToken(null);
    setUser(null);
  };

  const value = useMemo(
    () => ({
      user,
      token,
      isAuthenticated: Boolean(user && token),
      login,
      signup,
      logout,
    }),
    [user, token],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}

