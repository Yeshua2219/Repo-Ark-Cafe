const express = require("express");
const { login } = require("../controllers/authController");

const router = express.Router();

// Test authentication route
router.get("/test", (req, res) => {
  res.json({
    success: true,
    message: "ARK Cafe authentication route is working!"
  });
});

// Admin login
router.post("/login", login);

module.exports = router;
