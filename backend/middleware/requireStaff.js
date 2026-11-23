const { createClient } = require("@supabase/supabase-js");
const supabase = require("../config/database");

const requireStaff = async (req, res, next) => {
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

    const authKey =
      process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_SECRET_KEY;

    const authClient = createClient(
      process.env.SUPABASE_URL,
      authKey,
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

    const { data: profile, error: profileError } = await supabase
      .from("users")
      .select("id, full_name, email, role")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return res.status(403).json({
        message: "Unable to verify staff permissions.",
      });
    }

    if (!["employee", "admin"].includes(profile.role)) {
      return res.status(403).json({
        message: "Access denied. Staff only.",
      });
    }

    req.user = user;
    req.staffProfile = profile;

    next();
  } catch (error) {
    console.error("Staff middleware error:", error);

    return res.status(500).json({
      message: "An unexpected authentication error occurred.",
    });
  }
};

module.exports = requireStaff;