const express = require("express");
const router = express.Router();
const supabase = require("../config/database");

// GET ALL PRODUCTS
router.get("/", async (req, res) => {
    const { data, error } = await supabase
        .from("products")
        .select("*, categories(name)")
        .eq("is_available", true);

    if (error) {
        return res.status(500).json({
            message: error.message
        });
    }

    res.json(data);
});

module.exports = router;