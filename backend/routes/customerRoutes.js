const express = require("express");
const supabase = require("../config/database");
const { verifyUser } = require("../middleware/verifyUser");
const router = express.Router();

// A confirmed Auth user may provision their own customer profile only.
// Never accept a role, user ID or email from the request body.
router.post("/profile", verifyUser, async (req, res) => {
  try {
    const user = req.user;
    if (!user.email_confirmed_at || !user.email) {
      return res.status(403).json({ message: "Confirm your email first." });
    }
    const fields = "id, full_name, email, role, created_at";
    const { data: existing, error: lookupError } = await supabase
      .from("users").select(fields).eq("id", user.id).maybeSingle();
    if (lookupError) throw lookupError;
    if (existing && existing.role !== "customer") {
      return res.status(403).json({ message: "Use your authorized staff portal." });
    }
    const suppliedName = req.body?.full_name;
    const name = suppliedName === undefined
      ? (existing?.full_name || user.user_metadata?.full_name || "Customer")
      : suppliedName;
    if (typeof name !== "string" || !name.trim() || name.trim().length > 150) {
      return res.status(400).json({ message: "Enter a valid full name." });
    }
    const values = { full_name: name.trim(), email: user.email.trim().toLowerCase() };
    if (values.email.length > 150) {
      return res.status(400).json({ message: "Email exceeds profile length limit." });
    }
    if (!existing) {
      // Ignore duplicate ID on a concurrent request; never overwrite a role.
      const { error } = await supabase.from("users")
        .upsert({ id: user.id, ...values, role: "customer" },
          { onConflict: "id", ignoreDuplicates: true });
      if (error) throw error;
    } else if (suppliedName !== undefined || existing.email !== values.email) {
      const { error } = await supabase.from("users").update(values)
        .eq("id", user.id).eq("role", "customer");
      if (error) throw error;
    }
    const { data, error } = await supabase.from("users")
      .select(fields).eq("id", user.id).eq("role", "customer").single();
    if (error) throw error;
    return res.json(data);
  } catch (error) {
    console.error("Customer profile error:", error.code || error.message);
    return res.status(500).json({ message: "Unable to save customer profile." });
  }
});
module.exports = router;
