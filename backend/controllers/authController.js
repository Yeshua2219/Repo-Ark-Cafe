const { createClient } = require("@supabase/supabase-js");
const supabase = require("../config/database");

const authenticateWithRole = async (req, res, allowedRoles, deniedMessage) => {
  try {
    const { email, password } = req.body;

    if (
      typeof email !== "string" ||
      typeof password !== "string" ||
      !email.trim() ||
      !password
    ) {
      return res.status(400).json({
        message: "Email and password are required."
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
          autoRefreshToken: false
        }
      }
    );

    const { data, error } =
      await authClient.auth.signInWithPassword({
        email: email.trim(),
        password
      });

    if (error || !data?.user || !data?.session) {
      return res.status(401).json({
        message: "Invalid email or password."
      });
    }

    const { data: user, error: userError } = await supabase
      .from("users")
      .select("id, full_name, email, role")
      .eq("id", data.user.id)
      .single();

    if (userError || !user || !allowedRoles.includes(user.role)) {
      return res.status(403).json({
        message: deniedMessage
      });
    }

    return res.status(200).json({
      message: "Login successful.",
      token: data.session.access_token,
      user: {
        id: user.id,
        name: user.full_name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error("Login error:", error.message);

    return res.status(500).json({
      message: "An unexpected server error occurred."
    });
  }
};

const login = (req, res) =>
  authenticateWithRole(
    req,
    res,
    ["admin"],
    "Access denied. Administrators only."
  );

const employeeLogin = (req, res) =>
  authenticateWithRole(
    req,
    res,
    ["employee", "admin"],
    "Access denied. Employees only."
  );

module.exports = { login, employeeLogin };