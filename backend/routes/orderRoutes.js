const express = require("express");
const router = express.Router();
const supabase = require("../config/database");
const { verifyUser, requireRole } = require("../middleware/verifyUser");

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
      message: error.message,
    });
  }

  return res.json(data);
});

router.patch("/:id/status", verifyUser, requireRole("admin", "employee"), async (req, res) => {
  const { status } = req.body || {};

  const allowedStatuses = [
    "confirmed",
    "preparing",
    "ready",
  ];

  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({
      message: "Invalid order status",
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
      message: error.message,
    });
  }

  return res.json({
    message: "Order status updated",
    order: data,
  });
});

router.get("/mine", verifyUser, requireRole("customer"), async (req, res) => {
  const { data, error } = await supabase
    .from("orders")
    .select("*, order_items(*), payments(*)")
    .eq("customer_id", req.user.id)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Customer order history query failed:", error.code || "unknown", error.message);
    return res.status(500).json({ message: "Unable to load orders." });
  }

  return res.json(data);
});

router.post("/", verifyUser, requireRole("customer"), async (req, res) => {
  const { items, payment_method } = req.body || {};

  if (payment_method !== "cash") {
    return res.status(400).json({ message: "Online payment is not enabled yet." });
  }

  if (
    !Array.isArray(items) ||
    items.length < 1 ||
    items.length > 30 ||
    items.some(
      (item) =>
        !item ||
        !Number.isSafeInteger(item.product_id) ||
        item.product_id < 1 ||
        !Number.isInteger(item.quantity) ||
        item.quantity < 1 ||
        item.quantity > 30 ||
        (item.customization != null &&
          (typeof item.customization !== "string" || item.customization.length > 200))
    )
  ) {
    return res.status(400).json({ message: "Invalid order items." });
  }

  const normalizedItems = items.map((item) => ({
    product_id: item.product_id,
    quantity: item.quantity,
    customization: item.customization || "",
  }));

  const { data, error } = await supabase.rpc("ark_create_cash_order", {
    p_customer_id: req.user.id,
    p_items: normalizedItems,
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