import { useEffect, useState } from "react";
import { Store, CreditCard, Save } from "lucide-react";
import api from "../services/api";
import "../styles/settings.css";

export default function Settings() {
  const [settings, setSettings] = useState({
    cafe_name: "",
    address: "",
    opening_time: "",
    closing_time: "",
    payment_account_name: "",
    payment_qr_url: "",
    accepting_orders: false,
  });

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    api.get("/admin/settings")
      .then((response) => {
        setSettings((old) => ({ ...old, ...response.data }));
        setLoaded(true);
      })
      .catch(() => setError("Unable to load system settings."));
  }, []);

  const updateField = (name, value) => {
    setSettings((old) => ({ ...old, [name]: value }));
  };

  const saveSettings = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError("");
    setMessage("");

    try {
      await api.put("/admin/settings", settings);
      setMessage("System settings updated successfully.");
    } catch (err) {
      setError(err.response?.data?.message || "Unable to save settings.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div className="page-heading">
        <h1>System Settings</h1>
        <p>Manage ARK Cafe business and application configurations.</p>
      </div>

      {error && <div className="error-message">{error}</div>}
      {message && <div className="success-message">{message}</div>}

      <form onSubmit={saveSettings}>
        <fieldset disabled={!loaded || saving} className="settings-fieldset">
          <div className="settings-grid">
            <section className="panel">
              <div className="settings-title">
                <Store size={22} />
                <h3>Business Information</h3>
              </div>

              <div className="form-group">
                <label>Cafe Name</label>

                <input
                  value={settings.cafe_name}
                  onChange={(e) => updateField("cafe_name", e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label>Business Address</label>

                <textarea
                  rows="3"
                  value={settings.address}
                  onChange={(e) => updateField("address", e.target.value)}
                />
              </div>

              <div className="form-group">
                <label>Opening Time</label>

                <input
                  type="time"
                  value={settings.opening_time}
                  onChange={(e) => updateField("opening_time", e.target.value)}
                />
              </div>

              <div className="form-group">
                <label>Closing Time</label>

                <input
                  type="time"
                  value={settings.closing_time}
                  onChange={(e) => updateField("closing_time", e.target.value)}
                />
              </div>

              <div className="checkbox-field">
                <input
                  id="accepting-orders"
                  type="checkbox"
                  checked={settings.accepting_orders}
                  onChange={(e) =>
                    updateField("accepting_orders", e.target.checked)
                  }
                />

                <label htmlFor="accepting-orders">
                  Accept Online Orders
                </label>
              </div>
            </section>

            <section className="panel">
              <div className="settings-title">
                <CreditCard size={22} />
                <h3>Payment Configuration</h3>
              </div>

              <div className="form-group">
                <label>Payment Account Name</label>

                <input
                  value={settings.payment_account_name}
                  onChange={(e) =>
                    updateField("payment_account_name", e.target.value)
                  }
                />
              </div>

              <div className="form-group">
                <label>Payment QR Image URL</label>

                <input
                  type="url"
                  placeholder="https://..."
                  value={settings.payment_qr_url}
                  onChange={(e) =>
                    updateField("payment_qr_url", e.target.value)
                  }
                />
              </div>

              <div className="qr-preview">
                {settings.payment_qr_url.startsWith("https://") ? (
                  <img
                    src={settings.payment_qr_url}
                    alt="Payment QR code"
                    referrerPolicy="no-referrer"
                  />
                ) : (
                  <p>No payment QR code configured.</p>
                )}
              </div>

              <p className="muted">
                Online payments must be manually verified by employees.
              </p>
            </section>
          </div>

          <button
            className="primary-button save-settings-button"
            type="submit"
          >
            <Save size={18} />
            {saving ? "Saving..." : "Save Changes"}
          </button>
        </fieldset>
      </form>
    </div>
  );
}