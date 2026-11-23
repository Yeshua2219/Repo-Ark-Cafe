const express = require("express");
const supabase = require("../config/database");
const requireStaff = require("../middleware/requireStaff");

const router = express.Router();

function splitCategoryAndDescription(rawDescription) {
  const text = String(rawDescription || "");
  const match = text.match(/^\[([^\]]+)\]\s*(.*)$/);
  if (match) {
    return {
      category: match[1].trim() || "Other",
      description: match[2].trim(),
    };
  }
  return {
    category: "Other",
    description: text.trim(),
  };
}

function joinCategoryAndDescription(category, description) {
  const cleanCat =
    typeof category === "string" && category.trim() ? category.trim() : "Other";
  const cleanDesc = String(description || "").trim();
  return `[${cleanCat}] ${cleanDesc}`;
}

function serializeExpense(row) {
  const parsed = splitCategoryAndDescription(row.description);
  return {
    id: row.id,
    employee_id: row.employee_id,
    category: parsed.category,
    description: parsed.description,
    raw_description: row.description,
    amount: Number(row.amount || 0),
    expense_date: row.expense_date,
    created_at: row.created_at,
  };
}

router.get("/", requireStaff, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("expenses")
      .select("id, employee_id, description, amount, expense_date, created_at")
      .order("expense_date", { ascending: false })
      .order("id", { ascending: false });

    if (error) throw error;

    return res.json((data || []).map(serializeExpense));
  } catch (error) {
    console.error("Fetch expenses error:", error.message);
    return res.status(500).json({ message: "Unable to load expenses." });
  }
});

router.post("/", requireStaff, async (req, res) => {
  try {
    const { category, description, amount, expense_date } = req.body || {};
    const parsedAmount = Number(amount);

    if (!description || !String(description).trim()) {
      return res.status(400).json({ message: "Description is required." });
    }

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res
        .status(400)
        .json({ message: "Amount must be greater than zero." });
    }

    const formattedDesc = joinCategoryAndDescription(category, description);
    const dateValue =
      typeof expense_date === "string" && expense_date.trim()
        ? expense_date.trim().slice(0, 10)
        : new Date().toISOString().slice(0, 10);

    const { data, error } = await supabase
      .from("expenses")
      .insert({
        employee_id: req.staffProfile.id,
        description: formattedDesc,
        amount: parsedAmount,
        expense_date: dateValue,
      })
      .select("id, employee_id, description, amount, expense_date, created_at")
      .single();

    if (error) throw error;

    return res.status(201).json(serializeExpense(data));
  } catch (error) {
    console.error("Create expense error:", error.message);
    return res.status(500).json({ message: "Unable to record expense." });
  }
});

router.put("/:id", requireStaff, async (req, res) => {
  try {
    if (!/^\d+$/.test(req.params.id)) {
      return res.status(400).json({ message: "Invalid expense ID." });
    }

    const { category, description, amount, expense_date } = req.body || {};
    const parsedAmount = Number(amount);

    if (!description || !String(description).trim()) {
      return res.status(400).json({ message: "Description is required." });
    }

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res
        .status(400)
        .json({ message: "Amount must be greater than zero." });
    }

    const formattedDesc = joinCategoryAndDescription(category, description);
    const updates = {
      description: formattedDesc,
      amount: parsedAmount,
    };

    if (typeof expense_date === "string" && expense_date.trim()) {
      updates.expense_date = expense_date.trim().slice(0, 10);
    }

    const { data, error } = await supabase
      .from("expenses")
      .update(updates)
      .eq("id", Number(req.params.id))
      .select("id, employee_id, description, amount, expense_date, created_at")
      .single();

    if (error) throw error;

    return res.json(serializeExpense(data));
  } catch (error) {
    console.error("Update expense error:", error.message);
    return res.status(500).json({ message: "Unable to update expense." });
  }
});

router.delete("/:id", requireStaff, async (req, res) => {
  try {
    if (!/^\d+$/.test(req.params.id)) {
      return res.status(400).json({ message: "Invalid expense ID." });
    }

    const { error } = await supabase
      .from("expenses")
      .delete()
      .eq("id", Number(req.params.id));

    if (error) throw error;

    return res.json({ message: "Expense deleted." });
  } catch (error) {
    console.error("Delete expense error:", error.message);
    return res.status(500).json({ message: "Unable to delete expense." });
  }
});

module.exports = router;