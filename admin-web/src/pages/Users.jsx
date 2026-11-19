import { useEffect, useState, useCallback } from "react";
import { Plus, Search, Pencil, Trash2, X } from "lucide-react";
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
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const loadUsers = useCallback(async () => {
    try {
      const response = await api.get("/admin/users");
      setUsers(response.data);
      setError("");
    } catch {
      setError("Unable to load user accounts.");
    }
  }, []);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const openAdd = () => {
    setEditing(null);
    setForm(initialForm);
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

    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    const payload = { ...form };

    if (editing !== null && !payload.password) {
      delete payload.password;
    }

    try {
      if (editing !== null) {
        await api.put(`/admin/users/${editing}`, payload);
      } else {
        await api.post("/admin/users", payload);
      }

      setShowModal(false);
      await loadUsers();
    } catch (err) {
      setError(err.response?.data?.message || "Unable to save user.");
    } finally {
      setSaving(false);
    }
  };

  const deleteUser = async (id) => {
    if (!window.confirm("Are you sure you want to delete this account?")) {
      return;
    }

    try {
      await api.delete(`/admin/users/${id}`);
      await loadUsers();
    } catch (err) {
      setError(err.response?.data?.message || "Unable to delete user.");
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
        <p>Manage customer and employee accounts.</p>
      </div>

      {error && <div className="error-message">{error}</div>}

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

          <select value={role} onChange={(e) => setRole(e.target.value)}>
            <option value="">All Roles</option>
            <option value="customer">Customer</option>
            <option value="employee">Employee</option>
            <option value="admin">Admin</option>
          </select>

          <button className="primary-button" onClick={openAdd}>
            <Plus size={18} /> Add User
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
                    <span className={`role-badge ${user.role}`}>
                      {user.role}
                    </span>
                  </td>

                  <td>
                    {user.role !== "admin" && (
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
                          onClick={() => deleteUser(user.id)}
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
                  <td colSpan="4" className="empty-state">
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
              <h2>{editing !== null ? "Edit User" : "Add User"}</h2>

              <button
                className="close-button"
                onClick={() => setShowModal(false)}
              >
                <X size={23} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              {error && <div className="error-message">{error}</div>}

              <div className="form-group">
                <label>Full Name</label>

                <input
                  value={form.name}
                  onChange={(e) =>
                    setForm({ ...form, name: e.target.value })
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
                    setForm({ ...form, email: e.target.value })
                  }
                  required
                />
              </div>

              <div className="form-group">
                <label>
                  {editing !== null ? "New Password (Optional)" : "Password"}
                </label>

                <input
                  type="password"
                  minLength={8}
                  value={form.password}
                  onChange={(e) =>
                    setForm({ ...form, password: e.target.value })
                  }
                  required={editing === null}
                />
              </div>

              <div className="form-group">
                <label>Account Role</label>

                <select
                  value={form.role}
                  onChange={(e) =>
                    setForm({ ...form, role: e.target.value })
                  }
                >
                  <option value="employee">Employee</option>
                  <option value="customer">Customer</option>
                </select>
              </div>

              <div className="modal-actions">
                <button
                  type="button"
                  className="secondary-button"
                  onClick={() => setShowModal(false)}
                >
                  Cancel
                </button>

                <button
                  type="submit"
                  className="primary-button"
                  disabled={saving}
                >
                  {saving ? "Saving..." : "Save User"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}