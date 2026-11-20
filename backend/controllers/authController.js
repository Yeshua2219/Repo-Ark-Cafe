const { createClient } = require("@supabase/supabase-js");
const supabase = require("../config/database");

const login = async (req, res) => {
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

    // Create a separate client for password authentication.
    const authClient = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_PUBLISHABLE_KEY,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false
        }
      }
    );

    // Verify credentials through Supabase Authentication.
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

    // Check the trusted role stored in public.users.
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("id, full_name, email, role")
      .eq("id", data.user.id)
      .single();

   console.log("Authenticated user ID:", data.user.id);
    console.log("Database user:", user);
    console.log("Database lookup error:", userError?.message);
    console.log("Database lookup code:", userError?.code);

    if (userError || !user || user.role !== "admin") {
      return res.status(403).json({
        message: "Access denied. Administrators only."
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
    console.error("Admin login error:", error.message);

    return res.status(500).json({
      message: "An unexpected server error occurred."
    });
  }
};

module.exports = { login };
