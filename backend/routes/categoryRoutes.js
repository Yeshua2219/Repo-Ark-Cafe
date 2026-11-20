const express = require("express");
const router = express.Router();
const supabase = require("../config/database");

// GET ALL CATEGORIES
router.get("/", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("categories")
      .select("id, name")
      .order("name", { ascending: true });

    if (error) {
      console.error("Load categories error:", error);
      return res.status(500).json({
        message: error.message,
      });
    }

    res.json(data);
  } catch (error) {
    console.error("Categories error:", error);
    res.status(500).json({
      message: "Unable to load categories.",
    });
  }
});

module.exports = router;
