import { useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { Coffee, Mail, Lock, Eye, EyeOff } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import "../styles/login.css";

export default function Login() {
  const { admin, login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await login(email, password);
      navigate("/", { replace: true });
    } catch (err) {
      setError(
        err.response?.data?.message ||
        err.message ||
        "Unable to sign in."
      );
    } finally {
      setLoading(false);
    }
  };

  if (admin && sessionStorage.getItem("adminToken")) {
    return <Navigate to="/" replace />;
  }

  return (
    <div className="login-page">
      <section className="login-brand">
        <Coffee size={90} strokeWidth={1.4} />
        <h1>ARK CAFE</h1>
        <span>ADMIN PORTAL</span>
        <p>Brewing better management.</p>
      </section>

      <section className="login-section">
        <div className="login-form-container">
          <span className="login-label">ADMIN ACCESS</span>
          <h2>Welcome back!</h2>
          <p>Sign in to manage ARK Cafe.</p>

          <form onSubmit={handleLogin}>
            {error && <div className="error-message">{error}</div>}

            <label htmlFor="email">Email Address</label>

            <div className="login-input">
              <Mail size={19} />
              <input
                id="email"
                type="email"
                placeholder="Enter your email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>

            <label htmlFor="password">Password</label>

            <div className="login-input">
              <Lock size={19} />

              <input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />

              <button
                type="button"
                aria-label="Toggle password visibility"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>

            <button
              className="login-button"
              type="submit"
              disabled={loading}
            >
              {loading ? "Signing in..." : "Sign In"}
            </button>
          </form>

          <footer className="login-footer">
            ARK Cafe © 2026 | Authorized personnel only
          </footer>
        </div>
      </section>
    </div>
  );
}