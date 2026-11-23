import { UserRound } from "lucide-react";
import { useAuth } from "../context/AuthContext";

export default function Header() {
  const { admin } = useAuth();

  return (
    <header className="header">
      <div className="header-title">
        ARK Cafe Management System
      </div>

      <div className="admin-profile">
        <div className="avatar">
          <UserRound size={22} />
        </div>

        <div>
          <h4>{admin?.name || "Administrator"}</h4>
          <p>Administrator</p>
        </div>
      </div>
    </header>
  );
}