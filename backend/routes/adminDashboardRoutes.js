const express = require("express");
const supabase = require("../config/database");

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const period = req.query.period === "monthly" ? "monthly" : "weekly";
    const days = period === "monthly" ? 30 : 7;
    const sinceDate = new Date();
    sinceDate.setDate(sinceDate.getDate() - days);

    const [
      { data: orders, error: ordersError },
      { count: totalUsers, error: usersError },
      { count: totalProducts, error: productsError },
      { data: expenses, error: expensesError },
    ] = await Promise.all([
      supabase
        .from("orders")
        .select("id, customer_id, total_amount, payment_method, payment_status, order_status, created_at")
        .order("created_at", { ascending: false }),
      supabase
        .from("users")
        .select("id", { count: "exact", head: true }),
      supabase
        .from("products")
        .select("id", { count: "exact", head: true }),
      supabase
        .from("expenses")
        .select("amount"),
    ]);

    if (ordersError) throw ordersError;
    if (usersError) throw usersError;
    if (productsError) throw productsError;

    const allOrders = orders || [];
    const totalOrders = allOrders.length;
    const totalSales = allOrders.reduce(
      (sum, o) => sum + Number(o.total_amount || 0),
      0
    );

    const cashOrders = allOrders.filter(
      (o) => String(o.payment_method || "").toLowerCase() === "cash"
    ).length;
    const onlineOrders = allOrders.filter(
      (o) => String(o.payment_method || "").toLowerCase() !== "cash"
    ).length;

    const totalExpenses = (!expensesError && expenses ? expenses : []).reduce(
      (sum, e) => sum + Number(e.amount || 0),
      0
    );

    const chartMap = new Map();
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const key = d.toISOString().slice(0, 10);
      const label = d.toLocaleDateString("en-PH", {
        month: "short",
        day: "numeric",
      });
      chartMap.set(key, { label, sales: 0 });
    }

    allOrders.forEach((order) => {
      if (!order.created_at) return;
      const key = new Date(order.created_at).toISOString().slice(0, 10);
      if (chartMap.has(key)) {
        chartMap.get(key).sales += Number(order.total_amount || 0);
      }
    });

    const { data: orderItems } = await supabase
      .from("order_items")
      .select("product_id, quantity, products(name)");

    const productTotals = new Map();
    (orderItems || []).forEach((item) => {
      const name = item.products?.name || `Product #${item.product_id}`;
      productTotals.set(
        name,
        (productTotals.get(name) || 0) + Number(item.quantity || 0)
      );
    });

    const topProducts = Array.from(productTotals.entries())
      .map(([name, quantity]) => ({ name, quantity }))
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 5);

    const recentSlice = allOrders.slice(0, 5);
    const customerIds = [
      ...new Set(recentSlice.map((o) => o.customer_id).filter(Boolean)),
    ];

    let userNameMap = new Map();
    if (customerIds.length > 0) {
      const { data: customers } = await supabase
        .from("users")
        .select("id, full_name, email")
        .in("id", customerIds);

      (customers || []).forEach((c) => {
        userNameMap.set(c.id, c.full_name || c.email || "Customer");
      });
    }

    const recentTransactions = recentSlice.map((o) => ({
      id: o.id,
      order_id: `#${o.id}`,
      customer_name: userNameMap.get(o.customer_id) || "Customer",
      payment_method: o.payment_method || "cash",
      total_amount: o.total_amount || 0,
      status: o.order_status || "pending",
    }));

    return res.status(200).json({
      total_orders: totalOrders,
      total_sales: totalSales,
      total_users: totalUsers || 0,
      total_products: totalProducts || 0,
      cash_orders: cashOrders,
      online_orders: onlineOrders,
      sales_chart: Array.from(chartMap.values()),
      top_products: topProducts,
      total_expenses: totalExpenses,
      recent_transactions: recentTransactions,
    });
  } catch (error) {
    console.error("Dashboard load error:", error.message);
    return res.status(500).json({
      message: "Unable to load dashboard data.",
    });
  }
});

module.exports = router;