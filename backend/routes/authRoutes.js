const express = require("express");
const { login, employeeLogin } = require("../controllers/authController");

const router = express.Router();

router.get("/test", (req, res) => {
  res.json({
    success: true,
    message: "ARK Cafe authentication route is working!"
  });
});

router.post("/login", login);
router.post("/employee-login", employeeLogin);

module.exports = router;