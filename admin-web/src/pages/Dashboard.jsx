import { useEffect, useState } from "react";
import {
  ShoppingBag,
  Wallet,
  Users,
  Coffee,
  RefreshCw,
} from "lucide-react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import StatCard from "../components/StatCard";
import api from "../services/api";
import "../styles/dashboard.css";

const money = (value) =>
  Number(value || 0).toLocaleString("en-PH", {
    style: "currency",
    currency: "PHP",
  });

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [period, setPeriod] = useState("weekly");
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    api.get("/admin/dashboard", { params: { period } })
      .then((response) => {
        if (active) {
          setData(response.data);
          setError("");
        }
      })
      .catch(() => {
        if (active) {
          setData(null);
          setError("Unable to load dashboard data.");
        }
      });

    return () => {
      active = false;
    };
  }, [period]);

  const paymentData = [
    { name: "Cash", value: Number(data?.cash_orders || 0) },
    { name: "Online", value: Number(data?.online_orders || 0) },
  ];

  return (
    <div>
      <div className="page-heading heading-row">
        <div>
          <h1>Dashboard</h1>
          <p>Welcome back, Administrator!</p>
        </div>

        <select
          value={period}
          onChange={(e) => {
            setData(null);
            setError("");
            setPeriod(e.target.value);
          }}
        >
          <option value="weekly">Weekly Overview</option>
          <option value="monthly">Monthly Overview</option>
        </select>
      </div>

      {error && <div className="error-message">{error}</div>}

      {!data && !error && <p>Loading dashboard...</p>}

      <div className="stats-grid">
        <StatCard
          title="Total Orders"
          value={data?.total_orders ?? "—"}
          icon={ShoppingBag}
        />

        <StatCard
          title="Recorded Sales"
          value={data ? money(data.total_sales) : "—"}
          icon={Wallet}
        />

        <StatCard
          title="Registered Users"
          value={data?.total_users ?? "—"}
          icon={Users}
        />

        <StatCard
          title="Menu Items"
          value={data?.total_products ?? "—"}
          icon={Coffee}
        />
      </div>

      <div className="dashboard-grid">
        <section className="panel">
          <h3>Sales Overview</h3>
          <p className="muted">Recorded application sales</p>

          <div className="chart-container">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={data?.sales_chart || []}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="label" />
                <YAxis />
                <Tooltip formatter={(value) => money(value)} />
                <Bar
                  dataKey="sales"
                  fill="#876447"
                  radius={[6, 6, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </section>

        <section className="panel">
          <h3>Payment Methods</h3>
          <p className="muted">Cash and online payments</p>

          <ResponsiveContainer width="100%" height={260}>
            <PieChart>
              <Pie
                data={paymentData}
                dataKey="value"
                nameKey="name"
                innerRadius={55}
                outerRadius={85}
              >
                <Cell fill="#876447" />
                <Cell fill="#e8d7bd" />
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </section>

        <section className="panel">
          <h3>Top-Selling Products</h3>

          {(data?.top_products || []).map((product, index) => (
            <div className="top-product" key={index}>
              <span>{index + 1}. {product.name}</span>
              <strong>{product.quantity} sold</strong>
            </div>
          ))}

          {!data?.top_products?.length && (
            <p className="empty-state">No product statistics available.</p>
          )}
        </section>

        <section className="panel">
          <h3>Expense Summary</h3>

          <div className="summary-line">
            <span>Recorded Sales</span>
            <strong>{data ? money(data.total_sales) : "—"}</strong>
          </div>

          <div className="summary-line">
            <span>Miscellaneous Expenses</span>
            <strong>{data ? money(data.total_expenses) : "—"}</strong>
          </div>

          <div className="summary-line total-line">
            <span>Sales Less Recorded Expenses</span>

            <strong>
              {data
                ? money(
                    Number(data.total_sales || 0) -
                    Number(data.total_expenses || 0)
                  )
                : "—"}
            </strong>
          </div>

          <small className="muted">
            This amount does not represent actual net profit.
          </small>
        </section>
      </div>

      <section className="panel">
        <div className="heading-row">
          <h3>Recent Transactions</h3>

          <button
            className="secondary-button"
            onClick={() => window.location.reload()}
          >
            <RefreshCw size={15} /> Refresh
          </button>
        </div>

        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Order ID</th>
                <th>Customer</th>
                <th>Payment</th>
                <th>Amount</th>
                <th>Status</th>
              </tr>
            </thead>

            <tbody>
              {(data?.recent_transactions || []).map((item) => (
                <tr key={item.id}>
                  <td>{item.order_id}</td>
                  <td>{item.customer_name}</td>
                  <td>{item.payment_method}</td>
                  <td>{money(item.total_amount)}</td>
                  <td>{item.status}</td>
                </tr>
              ))}

              {!data?.recent_transactions?.length && (
                <tr>
                  <td colSpan="5" className="empty-state">
                    No transactions available.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}