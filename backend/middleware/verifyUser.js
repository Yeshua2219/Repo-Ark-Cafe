const { createClient } = require("@supabase/supabase-js");
const supabase = require("../config/database");

async function verifyUser(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const match = /^Bearer (\S+)$/i.exec(header);
    if (!match) return res.status(401).json({ message: "Sign in first." });

    const apiKey =
      process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_SECRET_KEY;
    const client = createClient(process.env.SUPABASE_URL, apiKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data, error } = await client.auth.getUser(match[1]);
    if (error || !data.user) {
      return res.status(401).json({ message: "Invalid or expired login." });
    }
    req.user = data.user;
    next();
  } catch (error) {
    console.error("Token verification failed:", error.message);
    return res.status(500).json({ message: "Unable to verify session." });
  }
}

function requireRole(...allowed) {
  return async (req, res, next) => {
    try {
      const { data, error } = await supabase
        .from("users")
        .select("id, role")
        .eq("id", req.user.id)
        .maybeSingle();
      if (error) throw error;
      if (!data || !allowed.includes(data.role)) {
        return res
          .status(403)
          .json({ message: "Account does not have permission." });
      }
      next();
    } catch (error) {
      console.error("Role lookup failed:", error.message);
      return res.status(500).json({ message: "Unable to verify permissions." });
    }
  };
}

module.exports = { verifyUser, requireRole };