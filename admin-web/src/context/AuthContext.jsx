import { createContext, useContext, useState } from "react";
import { loginAdmin } from "../services/authService";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [admin, setAdmin] = useState(() => {
    try {
      return JSON.parse(sessionStorage.getItem("admin"));
    } catch {
      return null;
    }
  });

  const login = async (email, password) => {
    const data = await loginAdmin(email, password);

    const user = data.user;
    const token = data.token;

    if (!user || user.role?.toLowerCase() !== "admin") {
      throw new Error("Access denied. Administrators only.");
    }

    if (!token) {
      throw new Error("No authentication token received.");
    }

    sessionStorage.setItem("adminToken", token);
    sessionStorage.setItem("admin", JSON.stringify(user));

    setAdmin(user);
  };

  const logout = () => {
    sessionStorage.removeItem("adminToken");
    sessionStorage.removeItem("admin");
    setAdmin(null);
  };

  return (
    <AuthContext.Provider value={{ admin, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}