
const express = require("express");
const router = express.Router();
const supabase = require("../config/database");

const settingKeys = [
  "cafe_name",
  "address",
  "opening_time",
  "closing_time",
  "payment_account_name",
  "payment_qr_url",
  "accepting_orders",
];

// GET SYSTEM SETTINGS
router.get("/", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("system_settings")
      .select("setting_name, setting_value")
      .in("setting_name", settingKeys);

    if (error) throw error;

    const settings = {
      cafe_name: "",
      address: "",
      opening_time: "",
      closing_time: "",
      payment_account_name: "",
      payment_qr_url: "",
      accepting_orders: false,
    };

    for (const row of data || []) {
      if (row.setting_name === "accepting_orders") {
        settings.accepting_orders =
          row.setting_value === "true";
      } else {
        settings[row.setting_name] =
          row.setting_value ?? "";
      }
    }

    return res.json(settings);
  } catch (error) {
    console.error("Load settings error:", error);

    return res.status(500).json({
      message: error.message || "Unable to load settings.",
    });
  }
});

// SAVE SYSTEM SETTINGS
router.put("/", async (req, res) => {
  try {
    const updates = {};

    for (const key of settingKeys) {
      if (Object.prototype.hasOwnProperty.call(req.body, key)) {
        updates[key] =
          key === "accepting_orders"
            ? String(req.body[key] === true)
            : String(req.body[key] ?? "");
      }
    }

    if (!Object.keys(updates).length) {
      return res.status(400).json({
        message: "No settings provided.",
      });
    }

    const { data: existing, error: readError } =
      await supabase
        .from("system_settings")
        .select("setting_name")
        .in("setting_name", Object.keys(updates));

    if (readError) throw readError;

    const existingNames = new Set(
      (existing || []).map((row) => row.setting_name)
    );

    // Update existing settings
    for (const [key, value] of Object.entries(updates)) {
      if (!existingNames.has(key)) continue;

      const { error } = await supabase
        .from("system_settings")
        .update({ setting_value: value })
        .eq("setting_name", key);

      if (error) throw error;
    }

    // Insert missing settings
    const missing = Object.entries(updates)
      .filter(([key]) => !existingNames.has(key))
      .map(([setting_name, setting_value]) => ({
        setting_name,
        setting_value,
      }));

    if (missing.length) {
      const { error } = await supabase
        .from("system_settings")
        .insert(missing);

      if (error) throw error;
    }

    return res.json({
      message: "System settings updated successfully.",
      settings: req.body,
    });
  } catch (error) {
    console.error("Save settings error:", error);

    return res.status(500).json({
      message: error.message || "Unable to save settings.",
    });
  }
});

module.exports = router;
