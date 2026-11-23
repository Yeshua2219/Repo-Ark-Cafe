
const express = require("express");
const router = express.Router();
const supabase = require("../config/database");

// GET ALL USERS
router.get("/", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("users")
      .select("id, full_name, email, role")
      .in("role", ["admin", "employee", "customer"])
      .order("full_name", { ascending: true });

    if (error) throw error;

    const users = data.map((user) => ({
      id: user.id,
      name: user.full_name,
      email: user.email,
      role: user.role,
    }));

    return res.json(users);
  } catch (error) {
    console.error("Load users error:", error);

    return res.status(500).json({
      message: "Unable to load user accounts.",
    });
  }
});

// ADD EMPLOYEE
router.post("/", async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (
      typeof name !== "string" ||
      !name.trim() ||
      typeof email !== "string" ||
      !email.trim() ||
      typeof password !== "string" ||
      password.length < 8
    ) {
      return res.status(400).json({
        message: "Enter a name, valid email, and password of at least 8 characters.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Check existing profile
    const { data: existing, error: lookupError } = await supabase
      .from("users")
      .select("id")
      .eq("email", normalizedEmail)
      .maybeSingle();

    if (lookupError) throw lookupError;

    if (existing) {
      return res.status(409).json({
        message: "An account with this email already exists.",
      });
    }

    // Create Supabase Auth account
    const { data: authData, error: authError } =
      await supabase.auth.admin.createUser({
        email: normalizedEmail,
        password,
        email_confirm: true,
      });

    if (authError) {
      return res.status(400).json({
        message: authError.message,
      });
    }

    const authUserId = authData.user.id;

    // Create database profile
    const { data: profile, error: profileError } = await supabase
      .from("users")
      .insert({
        id: authUserId,
        full_name: name.trim(),
        email: normalizedEmail,
        role: "employee",
      })
      .select("id, full_name, email, role")
      .single();

    if (profileError) {
      // Roll back the newly created Auth account.
      const { error: rollbackError } =
        await supabase.auth.admin.deleteUser(authUserId);

      if (rollbackError) {
        console.error("Auth rollback failed:", rollbackError);
      }

      console.error("Employee profile error:", profileError);

      return res.status(500).json({
        message: "Unable to create employee profile.",
      });
    }

    return res.status(201).json({
      message: "Employee account created successfully.",
      user: {
        id: profile.id,
        name: profile.full_name,
        email: profile.email,
        role: profile.role,
      },
    });
  } catch (error) {
    console.error("Add employee error:", error);

    return res.status(500).json({
      message: "Unable to save user.",
    });
  }
});

// UPDATE EMPLOYEE
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, password } = req.body;

    const { data: existing, error: lookupError } = await supabase
      .from("users")
      .select("id, full_name, email, role")
      .eq("id", id)
      .maybeSingle();

    if (lookupError) throw lookupError;

    if (!existing) {
      return res.status(404).json({
        message: "User not found.",
      });
    }

    if (existing.role !== "employee") {
      return res.status(403).json({
        message: "Administrator accounts cannot be modified here.",
      });
    }

    if (
      typeof name !== "string" ||
      !name.trim() ||
      typeof email !== "string" ||
      !email.trim() ||
      (password !== undefined &&
        (typeof password !== "string" ||
          password.length < 8))
    ) {
      return res.status(400).json({
        message: "Invalid employee details.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const authUpdates = {
      email: normalizedEmail,
      email_confirm: true,
    };

    if (password) {
      authUpdates.password = password;
    }

    // Update Supabase Authentication
    const { error: authError } =
      await supabase.auth.admin.updateUserById(id, authUpdates);

    if (authError) {
      return res.status(400).json({
        message: authError.message,
      });
    }

    // Update profile
    const { data, error } = await supabase
      .from("users")
      .update({
        full_name: name.trim(),
        email: normalizedEmail,
      })
      .eq("id", id)
      .select("id, full_name, email, role")
      .single();

    if (error) {
      console.error("Employee profile update error:", error);

      return res.status(500).json({
        message: "Authentication updated, but profile update failed. Please reconcile this account.",
      });
    }

    return res.json({
      message: "Employee updated successfully.",
      user: {
        id: data.id,
        name: data.full_name,
        email: data.email,
        role: data.role,
      },
    });
  } catch (error) {
    console.error("Update employee error:", error);

    return res.status(500).json({
      message: "Unable to update employee.",
    });
  }
});

// DELETE EMPLOYEE
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { data: existing, error: lookupError } = await supabase
      .from("users")
      .select("id, role")
      .eq("id", id)
      .maybeSingle();

    if (lookupError) throw lookupError;

    if (!existing) {
      return res.status(404).json({
        message: "User not found.",
      });
    }

    if (existing.role !== "employee") {
      return res.status(403).json({
        message: "Administrator accounts cannot be deleted.",
      });
    }

    // Delete the Supabase Auth user.
    const { error: authError } =
      await supabase.auth.admin.deleteUser(id);

    if (authError) {
      console.error("Delete Auth user error:", authError);

      return res.status(500).json({
        message: authError.message,
      });
    }

    // Delete profile if not already removed by a cascade.
    const { error: profileError } = await supabase
      .from("users")
      .delete()
      .eq("id", id);

    if (profileError) {
      console.error("Delete employee profile error:", profileError);

      return res.status(500).json({
        message: "Authentication account deleted, but profile cleanup failed.",
      });
    }

    return res.json({
      message: "Employee account deleted successfully.",
    });
  } catch (error) {
    console.error("Delete employee error:", error);

    return res.status(500).json({
      message: "Unable to delete employee.",
    });
  }
});

module.exports = router;
