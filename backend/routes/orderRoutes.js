const express = require("express");
const router = express.Router();
const supabase = require("../config/database");

// GET ALL ORDERS
router.get("/", async (req, res) => {
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
router.patch("/:id/status", async (req, res) => {
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

module.exports = router;