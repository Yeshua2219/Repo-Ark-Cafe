const express = require("express");
const supabase = require("../config/database");
const router = express.Router();

// Mounted behind Reivin's existing requireAdmin middleware.
function serialize(row) {
  return {
    id: row.id, order_id: row.id,
    customer_name: row.users?.full_name || "Customer",
    created_at: row.created_at, payment_method: row.payment_method,
    total_amount: row.total_amount, status: row.payment_status,
    order_status: row.order_status,
    items: (row.order_items || []).map(item => ({
      product_name: item.product_name, quantity: item.quantity,
      price: item.unit_price, customization: item.customization
    }))
  };
}
const select = "id, created_at, payment_method, total_amount, payment_status, order_status, users(full_name), order_items(product_name,quantity,unit_price,customization)";
router.get("/", async (req, res) => {
  const { data, error } = await supabase.from("orders").select(select)
    .order("created_at", { ascending: false });
  if (error) return res.status(500).json({ message: "Unable to load transactions." });
  return res.json(data.map(serialize));
});
router.get("/:id", async (req, res) => {
  if (!/^\d+$/.test(req.params.id)) {
    return res.status(400).json({ message: "Invalid transaction ID." });
  }
  const { data, error } = await supabase.from("orders").select(select)
    .eq("id", req.params.id).maybeSingle();
  if (error) return res.status(500).json({ message: "Unable to load transaction." });
  return data ? res.json(serialize(data)) :
    res.status(404).json({ message: "Transaction not found." });
});
module.exports = router;
