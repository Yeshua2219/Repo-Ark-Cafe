const express = require("express");
const router = express.Router();
const supabase = require("../config/database");
const { verifyUser, requireRole } = require("../middleware/verifyUser");
const { validatePaymentDecision } = require("../validation/paymentVerification");

// GET ALL ORDERS
router.get("/", verifyUser, requireRole("admin", "employee"), async (req, res) => {
    const { data, error } = await supabase
        .from("orders")
        .select(`
            *,
            order_items (*),
            payments (*)
        `)
        .order("created_at", { ascending: false });

    if (error) {
        return res.status(500).json({
            message: error.message
        });
    }

    res.json(data);
});

// UPDATE ORDER STATUS
router.patch("/:id/status", verifyUser, requireRole("admin", "employee"), async (req, res) => {
    const { status } = req.body;

    const allowedStatuses = [
        "confirmed",
        "preparing",
        "ready"
    ];

    if (!allowedStatuses.includes(status)) {
        return res.status(400).json({
            message: "Invalid order status"
        });
    }

    const { data, error } = await supabase
        .from("orders")
        .update({ order_status: status })
        .eq("id", req.params.id)
        .select()
        .single();

    if (error) {
        return res.status(500).json({
            message: error.message
        });
    }

    res.json({
        message: "Order status updated",
        order: data
    });
});

// Authorized staff-only cash verification. The SQL RPC updates both the
// orders payment status and the corresponding payments record atomically.
router.patch("/:id/payment", verifyUser, requireRole("admin", "employee"), async (req, res) => {
  const { orderId, status, error: validationError } =
    validatePaymentDecision(req.params.id, req.body);

  if (validationError) {
    return res.status(400).json({ message: validationError });
  }

  const { data, error } = await supabase.rpc("ark_verify_cash_payment", {
    p_order_id: orderId,
    p_decision: status,
    p_staff_id: req.user.id,
  });

  if (error) {
    console.error("Cash payment verification failed:", error.code || "unknown", error.message);
    if (error.code === "PGRST202" || error.code === "42501") {
      return res.status(503).json({
        message: "Payment verification database setup is pending. Ask the backend maintainer to apply the SQL script.",
      });
    }
    if (error.code === "P0001") {
      return res.status(409).json({
        message: "This cash payment could not be verified. Refresh the order and confirm it is still pending.",
      });
    }
    return res.status(500).json({ message: "Unable to verify payment." });
  }

  return res.json({
    message: status === "approved" ? "Cash receipt verified." : "Cash payment rejected.",
    order: data.order,
    payment: data.payment,
  });
});

// Customer history is always scoped to the verified token owner.
router.get("/mine", verifyUser, requireRole("customer"), async (req, res) => {
  const { data, error } = await supabase.from("orders")
    .select("*, order_items(*), payments(*)")
    .eq("customer_id", req.user.id)
    .order("created_at", { ascending: false });
  if (error) {
    console.error("Customer order history query failed:", error.code || "unknown", error.message);
    return res.status(500).json({ message: "Unable to load orders." });
  }
  return res.json(data);
});

// Cash orders use an atomic database function, not client-supplied prices.
router.post("/", verifyUser, requireRole("customer"), async (req, res) => {
  const { items, payment_method } = req.body || {};
  if (payment_method !== "cash") {
    return res.status(400).json({ message: "Online payment is not enabled yet." });
  }
  if (!Array.isArray(items) || items.length < 1 || items.length > 30 ||
      items.some(item => !item || !Number.isSafeInteger(item.product_id) ||
        item.product_id < 1 || !Number.isInteger(item.quantity) ||
        item.quantity < 1 || item.quantity > 30 ||
        (item.customization != null &&
          (typeof item.customization !== "string" || item.customization.length > 200)))) {
    return res.status(400).json({ message: "Invalid order items." });
  }
  const { data, error } = await supabase.rpc("ark_create_cash_order", {
    p_customer_id: req.user.id,
    p_items: items.map(item => ({ product_id: item.product_id,
      quantity: item.quantity, customization: item.customization || "" }))
  });
  if (error) {
    console.error("Create order error:", error.code || error.message);
    if (error.code === "P0001" || error.code === "22003") {
      return res.status(400).json({ message: "Order contains invalid or unavailable items." });
    }
    if (error.code === "PGRST202") {
      return res.status(503).json({ message: "Order database function is not deployed yet." });
    }
    return res.status(500).json({ message: "Unable to create order." });
  }
  return res.status(201).json({ order: data });
});

module.exports = router;