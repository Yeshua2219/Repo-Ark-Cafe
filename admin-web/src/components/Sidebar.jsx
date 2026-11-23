import { NavLink, useNavigate } from "react-router-dom";
import {
  Coffee,
  LayoutDashboard,
  Package,
  Users,
  ReceiptText,
  Settings,
  LogOut,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";

const menuItems = [
  { name: "Dashboard", path: "/", icon: LayoutDashboard },
  { name: "Products", path: "/products", icon: Package },
  { name: "User Management", path: "/users", icon: Users },
  { name: "Transactions", path: "/transactions", icon: ReceiptText },
  { name: "System Settings", path: "/settings", icon: Settings },
];

export default function Sidebar() {
  const { logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login", { replace: true });
  };

  return (
    <aside className="sidebar">
      <div className="brand">
        <Coffee size={36} />

        <div>
          <h2>ARK CAFE</h2>
          <p>ADMIN PORTAL</p>
        </div>
      </div>

      <p className="menu-label">MAIN MENU</p>

      <nav className="sidebar-menu">
        {menuItems.map(({ name, path, icon: Icon }) => (
          <NavLink
            key={path}
            to={path}
            end={path === "/"}
            className={({ isActive }) =>
              `nav-item ${isActive ? "active" : ""}`
            }
            title={name}
          >
            <Icon size={20} />
            <span>{name}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-bottom">
        <button className="logout-button" onClick={handleLogout}>
          <LogOut size={20} />
          <span>Logout</span>
        </button>

        <p>ARK Cafe Management System</p>
      </div>
    </aside>
  );
}