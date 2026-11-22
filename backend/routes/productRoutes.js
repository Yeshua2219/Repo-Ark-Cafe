
const express = require("express");
const router = express.Router();
const supabase = require("../config/database");

// GET AVAILABLE PRODUCTS
router.get("/", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("products")
      .select("*, categories(name)")
      .eq("is_available", true);

    if (error) {
      console.error("Load available products error:", error);

      return res.status(500).json({
        message: error.message,
      });
    }

    return res.json(data);
  } catch (error) {
    console.error("Products API error:", error);

    return res.status(500).json({
      message: "Unable to load products.",
    });
  }
});

module.exports = router;
