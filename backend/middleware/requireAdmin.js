
const { createClient } = require("@supabase/supabase-js");
const supabase = require("../config/database");

const requireAdmin = async (req, res, next) => {
  try {
    const authorization = req.headers.authorization;

    if (!authorization?.startsWith("Bearer ")) {
      return res.status(401).json({
        message: "Authentication token is required.",
      });
    }

    const token = authorization.slice(7).trim();

    if (!token) {
      return res.status(401).json({
        message: "Authentication token is required.",
      });
    }

    // Validate the access token with Supabase Auth.
    const authClient = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_PUBLISHABLE_KEY,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      }
    );

    const {
      data: { user },
      error: authError,
    } = await authClient.auth.getUser(token);

    if (authError || !user) {
      return res.status(401).json({
        message: "Invalid or expired session. Please log in again.",
      });
    }

    // Retrieve the user's role from the database.
    const { data: profile, error: profileError } =
      await supabase
        .from("users")
        .select("id, role")
        .eq("id", user.id)
        .single();

    if (profileError) {
      console.error("Admin authorization error:", profileError);

      return res.status(500).json({
        message: "Unable to verify administrator permissions.",
      });
    }

    if (profile?.role !== "admin") {
      return res.status(403).json({
        message: "Access denied. Administrators only.",
      });
    }

    req.user = user;
    req.adminProfile = profile;

    next();
  } catch (error) {
    console.error("Admin middleware error:", error);

    return res.status(500).json({
      message: "An unexpected authentication error occurred.",
    });
  }
};

module.exports = requireAdmin;
