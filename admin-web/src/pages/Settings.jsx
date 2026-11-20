
import { useEffect, useState } from "react";
import {
  Store,
  CreditCard,
  Save,
  RefreshCw,
} from "lucide-react";

import api from "../services/api";
import "../styles/settings.css";

// =====================================
// DEFAULT SETTINGS
// =====================================
const defaultSettings = {
  cafe_name: "",
  address: "",
  opening_time: "",
  closing_time: "",
  payment_account_name: "",
  payment_qr_url: "",
  accepting_orders: false,
};

// Convert database time to HTML time input
const formatTime = (value) => {
  if (!value) return "";

  return String(value).slice(0, 5);
};

export default function Settings() {
  // =====================================
  // STATE
  // =====================================
  const [settings, setSettings] = useState({
    ...defaultSettings,
  });

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // =====================================
  // LOAD SYSTEM SETTINGS
  // =====================================
  const loadSettings = async () => {
    setLoading(true);
    setError("");
    setMessage("");

    try {
      const response = await api.get("/admin/settings");

      const data = response.data?.settings ?? response.data;

      if (
        data &&
        typeof data === "object" &&
        !Array.isArray(data)
      ) {
        setSettings({
          ...defaultSettings,
          ...data,
          opening_time: formatTime(data.opening_time),
          closing_time: formatTime(data.closing_time),
          accepting_orders: Boolean(data.accepting_orders),
        });
      }
    } catch (err) {
      console.error("Load settings error:", {
        status: err.response?.status,
        data: err.response?.data,
        message: err.message,
      });

      setError(
        "Unable to load saved system settings. You can edit the fields, but saving requires a working backend connection."
      );
    } finally {
      setLoading(false);
    }
  };

  // =====================================
  // LOAD ON PAGE OPEN
  // =====================================
  useEffect(() => {
    loadSettings();
  }, []);

  // =====================================
  // UPDATE INPUT FIELD
  // =====================================
  const updateField = (name, value) => {
    setSettings((previous) => ({
      ...previous,
      [name]: value,
    }));

    if (message) {
      setMessage("");
    }
  };

  // =====================================
  // SAVE SYSTEM SETTINGS
  // =====================================
  const saveSettings = async (e) => {
    e.preventDefault();

    if (saving) return;

    setSaving(true);
    setError("");
    setMessage("");

    const payload = {
      cafe_name: settings.cafe_name.trim(),
      address: settings.address.trim(),
      opening_time: settings.opening_time || null,
      closing_time: settings.closing_time || null,
      payment_account_name:
        settings.payment_account_name.trim(),
      payment_qr_url: settings.payment_qr_url.trim(),
      accepting_orders: settings.accepting_orders,
    };

    try {
      const response = await api.put(
        "/admin/settings",
        payload
      );

      const updated =
        response.data?.settings ?? response.data;

      if (
        updated &&
        typeof updated === "object" &&
        !Array.isArray(updated)
      ) {
        setSettings((previous) => ({
          ...previous,
          ...updated,
          opening_time: formatTime(
            updated.opening_time ?? previous.opening_time
          ),
          closing_time: formatTime(
            updated.closing_time ?? previous.closing_time
          ),
        }));
      }

      setMessage(
        "System settings updated successfully."
      );
    } catch (err) {
      console.error("Save settings error:", {
        status: err.response?.status,
        data: err.response?.data,
        message: err.message,
      });

      setError(
        err.response?.data?.message ||
          "Unable to save system settings. Please try again."
      );
    } finally {
      setSaving(false);
    }
  };

  // =====================================
  // CHECK QR CODE URL
  // =====================================
  const qrUrl = settings.payment_qr_url.trim();

  const validQrUrl = (() => {
    try {
      return new URL(qrUrl).protocol === "https:";
    } catch {
      return false;
    }
  })();

  // =====================================
  // USER INTERFACE
  // =====================================
  return (
    <div>
      {/* PAGE HEADING */}
      <div className="page-heading">
        <h1>System Settings</h1>

        <p>
          Manage ARK Cafe business and application
          configurations.
        </p>
      </div>

      {/* ERROR MESSAGE */}
      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      {/* SUCCESS MESSAGE */}
      {message && (
        <div className="success-message">
          {message}
        </div>
      )}

      {/* SETTINGS FORM */}
      <form onSubmit={saveSettings}>
        <fieldset
          disabled={saving}
          className="settings-fieldset"
        >
          <div className="settings-grid">
            {/* =====================================
                BUSINESS INFORMATION
            ===================================== */}
            <section className="panel">
              <div className="settings-title">
                <Store size={22} />

                <h3>Business Information</h3>
              </div>

              {/* CAFE NAME */}
              <div className="form-group">
                <label htmlFor="cafe-name">
                  Cafe Name
                </label>

                <input
                  id="cafe-name"
                  type="text"
                  placeholder="Enter cafe name"
                  value={settings.cafe_name}
                  onChange={(e) =>
                    updateField(
                      "cafe_name",
                      e.target.value
                    )
                  }
                  required
                />
              </div>

              {/* BUSINESS ADDRESS */}
              <div className="form-group">
                <label htmlFor="business-address">
                  Business Address
                </label>

                <textarea
                  id="business-address"
                  rows={3}
                  placeholder="Enter business address"
                  value={settings.address}
                  onChange={(e) =>
                    updateField(
                      "address",
                      e.target.value
                    )
                  }
                />
              </div>

              {/* OPENING TIME */}
              <div className="form-group">
                <label htmlFor="opening-time">
                  Opening Time
                </label>

                <input
                  id="opening-time"
                  type="time"
                  value={settings.opening_time}
                  onChange={(e) =>
                    updateField(
                      "opening_time",
                      e.target.value
                    )
                  }
                />
              </div>

              {/* CLOSING TIME */}
              <div className="form-group">
                <label htmlFor="closing-time">
                  Closing Time
                </label>

                <input
                  id="closing-time"
                  type="time"
                  value={settings.closing_time}
                  onChange={(e) =>
                    updateField(
                      "closing_time",
                      e.target.value
                    )
                  }
                />
              </div>

              {/* ACCEPT ONLINE ORDERS */}
              <div className="checkbox-field">
                <input
                  id="accepting-orders"
                  type="checkbox"
                  checked={settings.accepting_orders}
                  onChange={(e) =>
                    updateField(
                      "accepting_orders",
                      e.target.checked
                    )
                  }
                />

                <label htmlFor="accepting-orders">
                  Accept Online Orders
                </label>
              </div>
            </section>

            {/* =====================================
                PAYMENT CONFIGURATION
            ===================================== */}
            <section className="panel">
              <div className="settings-title">
                <CreditCard size={22} />

                <h3>Payment Configuration</h3>
              </div>

              {/* PAYMENT ACCOUNT NAME */}
              <div className="form-group">
                <label htmlFor="payment-account">
                  Payment Account Name
                </label>

                <input
                  id="payment-account"
                  type="text"
                  placeholder="Enter payment account name"
                  value={settings.payment_account_name}
                  onChange={(e) =>
                    updateField(
                      "payment_account_name",
                      e.target.value
                    )
                  }
                />
              </div>

              {/* PAYMENT QR URL */}
              <div className="form-group">
                <label htmlFor="payment-qr">
                  Payment QR Image URL
                </label>

                <input
                  id="payment-qr"
                  type="url"
                  placeholder="https://..."
                  value={settings.payment_qr_url}
                  onChange={(e) =>
                    updateField(
                      "payment_qr_url",
                      e.target.value
                    )
                  }
                />
              </div>

              {/* QR CODE PREVIEW */}
              <div className="qr-preview">
                {validQrUrl ? (
                  <img
                    src={qrUrl}
                    alt="Payment QR code preview"
                    referrerPolicy="no-referrer"
                    onError={(e) => {
                      e.currentTarget.style.display =
                        "none";
                    }}
                    onLoad={(e) => {
                      e.currentTarget.style.display =
                        "block";
                    }}
                  />
                ) : (
                  <p>
                    No payment QR code configured.
                  </p>
                )}
              </div>

              {/* PAYMENT INFORMATION */}
              <p className="muted">
                Online payments must be manually
                verified by employees.
              </p>
            </section>
          </div>

          {/* =====================================
              ACTION BUTTONS
          ===================================== */}
          <div
            className="modal-actions"
            style={{
              marginTop: "24px",
              justifyContent: "flex-end",
            }}
          >
            {/* RELOAD SETTINGS */}
            <button
              type="button"
              className="secondary-button"
              onClick={loadSettings}
              disabled={loading || saving}
            >
              <RefreshCw size={18} />
              {loading ? "Loading..." : "Reload"}
            </button>

            {/* SAVE SETTINGS */}
            <button
              type="submit"
              className="primary-button save-settings-button"
              disabled={saving}
            >
              <Save size={18} />

              {saving
                ? "Saving..."
                : "Save Changes"}
            </button>
          </div>
        </fieldset>
      </form>
    </div>
  );
}
