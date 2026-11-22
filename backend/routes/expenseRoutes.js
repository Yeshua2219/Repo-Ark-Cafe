const express = require("express");

const router = express.Router();

// Temporary endpoint to test the expense router
router.get("/test", (req, res) => {
    res.json({
        success: true,
        message: "ARK Cafe expense route is working!"
    });
});

module.exports = router;