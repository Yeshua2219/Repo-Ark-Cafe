
const express = require("express");
const cors = require("cors");
require("dotenv").config();

const requireAdmin = require("./middleware/requireAdmin");
const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "ARK Cafe API is running!",
  });
});

app.use("/api/auth", require("./routes/authRoutes"));

app.use("/api/products", require("./routes/productRoutes"));
app.use("/api/customer", require("./routes/customerRoutes"));
app.use("/api/admin/transactions", requireAdmin, require("./routes/adminTransactionRoutes"));
app.use("/api/orders", require("./routes/orderRoutes"));
app.use("/api/expenses", require("./routes/expenseRoutes"));

app.use(
  "/api/categories",
  requireAdmin,
  require("./routes/categoryRoutes")
);

app.use(
  "/api/admin/products",
  requireAdmin,
  require("./routes/adminProductRoutes")
);

app.use(
  "/api/admin/users",
  requireAdmin,
  require("./routes/adminUserRoutes")
);

app.use(
  "/api/admin/settings",
  requireAdmin,
  require("./routes/adminSettingsRoutes")
);


app.use((req, res) => {
  res.status(404).json({
    message: "API endpoint not found.",
  });
});

app.use((err, req, res, next) => {
  console.error("Server error:", err);

  res.status(500).json({
    message: "Internal server error.",
  });
});


const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
