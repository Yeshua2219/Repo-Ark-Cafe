
const express = require("express");
const router = express.Router();
const supabase = require("../config/database");

// GET ALL PRODUCTS (ADMIN)
router.get("/", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("products")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;

    return res.json(data);
  } catch (error) {
    console.error("Load products error:", error);

    return res.status(500).json({
      message: error.message || "Unable to load products.",
    });
  }
});

// ADD PRODUCT
router.post("/", async (req, res) => {
  try {
    const {
      name,
      category_id,
      description,
      price,
      is_available,
    } = req.body;

    if (
      typeof name !== "string" ||
      !name.trim() ||
      !category_id ||
      price === "" ||
      price === null ||
      price === undefined ||
      !Number.isFinite(Number(price)) ||
      Number(price) < 0
    ) {
      return res.status(400).json({
        message: "Please enter valid product details.",
      });
    }

    const { data, error } = await supabase
      .from("products")
      .insert({
        name: name.trim(),
        category_id,
        description: description || "",
        price: Number(price),
        is_available: is_available !== false,
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      message: "Product added successfully.",
      product: data,
    });
  } catch (error) {
    console.error("Add product error:", error);

    return res.status(500).json({
      message: error.message || "Unable to add product.",
    });
  }
});

// UPDATE PRODUCT
router.put("/:id", async (req, res) => {
  try {
    const {
      name,
      category_id,
      description,
      price,
      is_available,
    } = req.body;

    if (
      typeof name !== "string" ||
      !name.trim() ||
      !category_id ||
      price === "" ||
      price === null ||
      price === undefined ||
      !Number.isFinite(Number(price)) ||
      Number(price) < 0
    ) {
      return res.status(400).json({
        message: "Please enter valid product details.",
      });
    }

    const { data, error } = await supabase
      .from("products")
      .update({
        name: name.trim(),
        category_id,
        description: description || "",
        price: Number(price),
        is_available: is_available !== false,
      })
      .eq("id", req.params.id)
      .select()
      .maybeSingle();

    if (error) throw error;

    if (!data) {
      return res.status(404).json({
        message: "Product not found.",
      });
    }

    return res.json({
      message: "Product updated successfully.",
      product: data,
    });
  } catch (error) {
    console.error("Update product error:", error);

    return res.status(500).json({
      message: error.message || "Unable to update product.",
    });
  }
});

// DELETE PRODUCT
router.delete("/:id", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("products")
      .delete()
      .eq("id", req.params.id)
      .select("id");

    if (error) throw error;

    if (!data?.length) {
      return res.status(404).json({
        message: "Product not found.",
      });
    }

    return res.json({
      message: "Product deleted successfully.",
    });
  } catch (error) {
    console.error("Delete product error:", error);

    return res.status(500).json({
      message: error.message || "Unable to delete product.",
    });
  }
});

module.exports = router;
