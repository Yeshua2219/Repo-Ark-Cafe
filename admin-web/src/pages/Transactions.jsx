import { useEffect, useState } from "react";
import { Search, Eye, X } from "lucide-react";
import api from "../services/api";
import "../styles/transactions.css";

export default function Transactions() {
  const [transactions, setTransactions] = useState([]);
  const [search, setSearch] = useState("");
  const [paymentMethod, setPaymentMethod] = useState("");
  const [date, setDate] = useState("");
  const [selected, setSelected] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    api.get("/admin/transactions")
      .then((response) => setTransactions(response.data))
      .catch(() => setError("Unable to load transactions."));
  }, []);

  const formatDate = (value) =>
    new Date(value).toLocaleDateString("en-CA", {
      timeZone: "Asia/Manila",
    });

  const filteredTransactions = transactions.filter((item) => {
    const matchesSearch =
      `${item.order_id} ${item.customer_name}`
        .toLowerCase()
        .includes(search.toLowerCase());

    const matchesPayment =
      !paymentMethod || item.payment_method === paymentMethod;

    const matchesDate =
      !date || formatDate(item.created_at) === date;

    return matchesSearch && matchesPayment && matchesDate;
  });

  const viewTransaction = async (id) => {
    try {
      const response = await api.get(`/admin/transactions/${id}`);
      setSelected(response.data);
    } catch {
      setError("Unable to load transaction details.");
    }
  };

  return (
    <div>
      <div className="page-heading">
        <h1>Transaction History</h1>
        <p>View all recorded ARK Cafe application transactions.</p>
      </div>

      {error && <div className="error-message">{error}</div>}

      <section className="panel">
        <div className="toolbar">
          <div className="search-box">
            <Search size={19} />

            <input
              placeholder="Search transactions..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <select
            value={paymentMethod}
            onChange={(e) => setPaymentMethod(e.target.value)}
          >
            <option value="">All Payment Methods</option>
            <option value="cash">Cash</option>
            <option value="online">Online</option>
          </select>

          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
          />

          <button
            className="secondary-button"
            onClick={() => {
              setSearch("");
              setPaymentMethod("");
              setDate("");
            }}
          >
            Clear Filters
          </button>
        </div>

        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Order ID</th>
                <th>Customer</th>
                <th>Date</th>
                <th>Payment</th>
                <th>Total Amount</th>
                <th>Status</th>
                <th>Details</th>
              </tr>
            </thead>

            <tbody>
              {filteredTransactions.map((item) => (
                <tr key={item.id}>
                  <td>{item.order_id}</td>
                  <td>{item.customer_name}</td>
                  <td>{formatDate(item.created_at)}</td>

                  <td className="capitalize">
                    {item.payment_method}
                  </td>

                  <td>₱{Number(item.total_amount).toFixed(2)}</td>

                  <td>
                    <span
                      className={`status-badge ${
                        item.status === "paid" ? "active" : "neutral"
                      }`}
                    >
                      {item.status}
                    </span>
                  </td>

                  <td>
                    <button
                      className="edit-button"
                      title="View transaction"
                      onClick={() => viewTransaction(item.id)}
                    >
                      <Eye size={17} />
                    </button>
                  </td>
                </tr>
              ))}

              {!filteredTransactions.length && (
                <tr>
                  <td colSpan="7" className="empty-state">
                    No transactions to display.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {selected && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-header">
              <h2>Transaction Details</h2>

              <button
                className="close-button"
                onClick={() => setSelected(null)}
              >
                <X size={23} />
              </button>
            </div>

            <div className="transaction-details">
              <p>Order ID: <strong>{selected.order_id}</strong></p>
              <p>Customer: <strong>{selected.customer_name}</strong></p>
              <p>Payment: <strong>{selected.payment_method}</strong></p>
              <p>Status: <strong>{selected.status}</strong></p>
            </div>

            <table>
              <thead>
                <tr>
                  <th>Item</th>
                  <th>Qty</th>
                  <th>Price</th>
                </tr>
              </thead>

              <tbody>
                {(selected.items || []).map((item, index) => (
                  <tr key={index}>
                    <td>{item.product_name}</td>
                    <td>{item.quantity}</td>
                    <td>₱{Number(item.price).toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="transaction-total">
              Total: ₱{Number(selected.total_amount).toFixed(2)}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}