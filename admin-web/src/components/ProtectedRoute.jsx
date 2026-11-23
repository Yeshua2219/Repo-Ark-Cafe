import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function ProtectedRoute() {
  const { admin } = useAuth();

  const token = sessionStorage.getItem("adminToken");

  if (!admin || !token || admin.role?.toLowerCase() !== "admin") {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}