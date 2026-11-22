
import { useEffect, useState, useCallback } from "react";
import {
  Plus,
  Search,
  Pencil,
  Trash2,
  X,
  Eye,
  EyeOff,
} from "lucide-react";
import api from "../services/api";
import "../styles/users.css";

const initialForm = {
  name: "",
  email: "",
  password: "",
  role: "employee",
};

export default function Users() {
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState("");
  const [role, setRole] = useState("");
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(initialForm);
  const [showModal, setShowModal] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [modalError, setModalError] = useState("");
  const [saving, setSaving] = useState(false);

  const loadUsers = useCallback(async () => {
    try {
      const response = await api.get("/admin/users");

      setUsers(response.data);
      setError("");
    } catch (err) {
      console.error("Load users error:", err.response?.data || err);

      setError(
        err.response?.data?.message ||
          "Unable to load user accounts."
      );
    }
  }, []);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const openAdd = () => {
    setEditing(null);
    setForm({ ...initialForm });
    setShowPassword(false);
    setModalError("");
    setShowModal(true);
  };

  const openEdit = (user) => {
    setEditing(user.id);

    setForm({
      name: user.name,
      email: user.email,
      password: "",
      role: user.role,
    });

    setShowPassword(false);
    setModalError("");
    setShowModal(true);
  };

  const closeModal = () => {
    if (saving) return;

    setShowModal(false);
    setModalError("");
    setShowPassword(false);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    setSaving(true);
    setModalError("");

    const payload = {
      name: form.name.trim(),
      email: form.email.trim().toLowerCase(),
      role: "employee",
    };

    if (form.password) {
      payload.password = form.password;
    }

    try {
      if (editing !== null) {
        await api.put(`/admin/users/${editing}`, payload);
      } else {
        await api.post("/admin/users", payload);
      }

      setShowModal(false);
      setShowPassword(false);

      await loadUsers();
    } catch (err) {
      console.error("Save user error:", {
        status: err.response?.status,
        data: err.response?.data,
        message: err.message,
      });

      setModalError(
        err.response?.data?.message ||
          `Unable to save user${
            err.response?.status
              ? ` (HTTP ${err.response.status})`
              : ""
          }.`
      );
    } finally {
      setSaving(false);
    }
  };

  const deleteUser = async (id) => {
    if (
      !window.confirm(
        "Are you sure you want to delete this account?"
      )
    ) {
      return;
    }

    try {
      await api.delete(`/admin/users/${id}`);
      await loadUsers();
    } catch (err) {
      console.error("Delete user error:", err);

      setError(
        err.response?.data?.message ||
          "Unable to delete user."
      );
    }
  };

  const filteredUsers = users.filter((user) => {
    const matchesSearch = `${user.name} ${user.email}`
      .toLowerCase()
      .includes(search.toLowerCase());

    return matchesSearch && (!role || user.role === role);
  });

  return (
    <div>
      <div className="page-heading">
        <h1>User Management</h1>
        <p>Manage staff accounts and view registered customers.</p>
      </div>

      {error && (
        <div className="error-message">{error}</div>
      )}

      <section className="panel">
        <div className="toolbar">
          <div className="search-box">
            <Search size={18} />

            <input
              placeholder="Search users..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
          >
            <option value="">All Roles</option>
            <option value="employee">Employee</option>
            <option value="admin">Admin</option>
            <option value="customer">Customer</option>
          </select>

          <button
            className="primary-button"
            onClick={openAdd}
          >
            <Plus size={18} />
            Add User
          </button>
        </div>

        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email Address</th>
                <th>Role</th>
                <th>Actions</th>
              </tr>
            </thead>

            <tbody>
              {filteredUsers.map((user) => (
                <tr key={user.id}>
                  <td>{user.name}</td>
                  <td>{user.email}</td>

                  <td>
                    <span
                      className={`role-badge ${user.role}`}
                    >
                      {user.role}
                    </span>
                  </td>

                  <td>
                    {user.role === "employee" && (
                      <div className="action-buttons">
                        <button
                          className="edit-button"
                          title="Edit user"
                          onClick={() => openEdit(user)}
                        >
                          <Pencil size={16} />
                        </button>

                        <button
                          className="delete-button"
                          title="Delete user"
                          onClick={() =>
                            deleteUser(user.id)
                          }
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}

              {!filteredUsers.length && (
                <tr>
                  <td
                    colSpan="4"
                    className="empty-state"
                  >
                    No user accounts to display.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {showModal && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-header">
              <h2>
                {editing !== null
                  ? "Edit User"
                  : "Add User"}
              </h2>

              <button
                type="button"
                className="close-button"
                onClick={closeModal}
                disabled={saving}
              >
                <X size={23} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              {modalError && (
                <div className="error-message">
                  {modalError}
                </div>
              )}

              <div className="form-group">
                <label>Full Name</label>

                <input
                  value={form.name}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      name: e.target.value,
                    })
                  }
                  required
                />
              </div>

              <div className="form-group">
                <label>Email Address</label>

                <input
                  type="email"
                  value={form.email}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      email: e.target.value,
                    })
                  }
                  required
                />
              </div>

              <div className="form-group">
                <label>
                  {editing !== null
                    ? "New Password (Optional)"
                    : "Password"}
                </label>

                <div className="user-password-wrapper">
                  <input
                    type={
                      showPassword
                        ? "text"
                        : "password"
                    }
                    minLength={8}
                    value={form.password}
                    onChange={(e) =>
                      setForm({
                        ...form,
                        password: e.target.value,
                      })
                    }
                    autoComplete="new-password"
                    required={editing === null}
                  />

                  <button
                    type="button"
                    className="user-password-toggle"
                    onClick={() =>
                      setShowPassword((prev) => !prev)
                    }
                    aria-label={
                      showPassword
                        ? "Hide password"
                        : "Show password"
                    }
                    title={
                      showPassword
                        ? "Hide password"
                        : "Show password"
                    }
                  >
                    {showPassword ? (
                      <EyeOff size={20} />
                    ) : (
                      <Eye size={20} />
                    )}
                  </button>
                </div>
              </div>

              <div className="form-group">
                <label>Account Role</label>

                <select
                  value="employee"
                  disabled
                >
                  <option value="employee">
                    Employee
                  </option>
                </select>
              </div>

              <div className="modal-actions">
                <button
                  type="button"
                  className="secondary-button"
                  onClick={closeModal}
                  disabled={saving}
                >
                  Cancel
                </button>

                <button
                  type="submit"
                  className="primary-button"
                  disabled={saving}
                >
                  {saving
                    ? "Saving..."
                    : "Save User"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
