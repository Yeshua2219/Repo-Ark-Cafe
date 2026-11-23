
import { useEffect, useState, useCallback } from "react";
import {
  Plus,
  Search,
  Pencil,
  Trash2,
  X,
} from "lucide-react";

import api from "../services/api";
import "../styles/products.css";

// Default Product Form
const initialForm = {
  name: "",
  category_id: "",
  description: "",
  price: "",
  is_available: true,
};

export default function Products() {
  // Product and Category Data
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);

  // Search and Filtering
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");

  // Form and Modal
  const [form, setForm] = useState({ ...initialForm });
  const [editing, setEditing] = useState(null);
  const [showModal, setShowModal] = useState(false);

  // Loading and Error States
  const [error, setError] = useState("");
  const [modalError, setModalError] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // =====================================
  // LOAD PRODUCTS AND CATEGORIES
  // =====================================
  const loadProducts = useCallback(async () => {
    setLoading(true);

    const results = await Promise.allSettled([
      api.get("/admin/products"),
      api.get("/categories"),
    ]);

    const [productResult, categoryResult] = results;
    const errors = [];

    // Load Products
    if (productResult.status === "fulfilled") {
      const productData = productResult.value.data;

      setProducts(
        Array.isArray(productData) ? productData : []
      );
    } else {
      const err = productResult.reason;

      console.error("Products API error:", {
        status: err.response?.status,
        data: err.response?.data,
        message: err.message,
      });

      errors.push(
        err.response?.data?.message ||
          "Unable to load products."
      );
    }

    // Load Categories
    if (categoryResult.status === "fulfilled") {
      const categoryData = categoryResult.value.data;

      setCategories(
        Array.isArray(categoryData) ? categoryData : []
      );
    } else {
      const err = categoryResult.reason;

      console.error("Categories API error:", {
        status: err.response?.status,
        data: err.response?.data,
        message: err.message,
      });

      errors.push(
        err.response?.data?.message ||
          "Unable to load categories."
      );
    }

    setError(errors.join(" "));
    setLoading(false);
  }, []);

  // =====================================
  // LOAD DATA ON PAGE OPEN
  // =====================================
  useEffect(() => {
    loadProducts();
  }, [loadProducts]);

  // =====================================
  // OPEN ADD PRODUCT MODAL
  // =====================================
  const openAdd = () => {
    setEditing(null);
    setForm({ ...initialForm });
    setModalError("");
    setShowModal(true);
  };

  // =====================================
  // OPEN EDIT PRODUCT MODAL
  // =====================================
  const openEdit = (product) => {
    setEditing(product.id);

    setForm({
      name: product.name || "",
      category_id: String(product.category_id ?? ""),
      description: product.description || "",
      price: String(product.price ?? ""),
      is_available: product.is_available ?? true,
    });

    setModalError("");
    setShowModal(true);
  };

  // =====================================
  // CLOSE MODAL
  // =====================================
  const closeModal = () => {
    if (saving) return;

    setShowModal(false);
    setModalError("");
    setEditing(null);
  };

  // =====================================
  // HANDLE FORM INPUT
  // =====================================
  const handleChange = (field, value) => {
    setForm((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  // =====================================
  // ADD OR UPDATE PRODUCT
  // =====================================
  const handleSubmit = async (e) => {
    e.preventDefault();

    if (saving) return;

    setModalError("");

    const name = form.name.trim();
    const price = Number(form.price);

    if (!name) {
      setModalError("Product name is required.");
      return;
    }

    if (!form.category_id) {
      setModalError("Please select a category.");
      return;
    }

    if (
      form.price === "" ||
      !Number.isFinite(price) ||
      price < 0
    ) {
      setModalError("Please enter a valid price.");
      return;
    }

    const payload = {
      name,
      category_id: Number(form.category_id),
      description: form.description.trim(),
      price,
      is_available: form.is_available,
    };

    setSaving(true);

    try {
      if (editing !== null) {
        await api.put(
          `/admin/products/${editing}`,
          payload
        );
      } else {
        await api.post("/admin/products", payload);
      }

      setShowModal(false);
      setEditing(null);
      setForm({ ...initialForm });

      await loadProducts();
    } catch (err) {
      console.error("Save product error:", {
        status: err.response?.status,
        data: err.response?.data,
        message: err.message,
      });

      setModalError(
        err.response?.data?.message ||
          "Unable to save product. Please try again."
      );
    } finally {
      setSaving(false);
    }
  };

  // =====================================
  // DELETE PRODUCT
  // =====================================
  const deleteProduct = async (id) => {
    const confirmed = window.confirm(
      "Are you sure you want to delete this product?"
    );

    if (!confirmed) return;

    try {
      await api.delete(`/admin/products/${id}`);
      await loadProducts();
    } catch (err) {
      console.error("Delete product error:", err);

      setError(
        err.response?.data?.message ||
          "Unable to delete product."
      );
    }
  };

  // =====================================
  // FILTER PRODUCTS
  // =====================================
  const filteredProducts = products.filter((product) => {
    const matchesSearch = String(product.name || "")
      .toLowerCase()
      .includes(search.toLowerCase());

    const matchesCategory =
      !category ||
      String(product.category_id) === String(category);

    return matchesSearch && matchesCategory;
  });

  // =====================================
  // GET CATEGORY NAME
  // =====================================
  const categoryName = (id) => {
    const found = categories.find(
      (item) => String(item.id) === String(id)
    );

    return found?.name || "Uncategorized";
  };

  // =====================================
  // USER INTERFACE
  // =====================================
  return (
    <div>
      {/* PAGE HEADING */}
      <div className="page-heading">
        <h1>Product Management</h1>
        <p>Manage ARK Cafe food and beverages.</p>
      </div>

      {/* PAGE ERROR */}
      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      <section className="panel">
        {/* TOOLBAR */}
        <div className="toolbar">
          <div className="search-box">
            <Search size={19} />

            <input
              type="text"
              placeholder="Search products..."
              value={search}
              onChange={(e) =>
                setSearch(e.target.value)
              }
            />
          </div>

          {/* CATEGORY FILTER */}
          <select
            value={category}
            onChange={(e) =>
              setCategory(e.target.value)
            }
          >
            <option value="">All Categories</option>

            {categories.map((item) => (
              <option
                key={item.id}
                value={String(item.id)}
              >
                {item.name}
              </option>
            ))}
          </select>

          {/* ADD PRODUCT */}
          <button
            type="button"
            className="primary-button"
            onClick={openAdd}
          >
            <Plus size={18} />
            Add Product
          </button>
        </div>

        {/* PRODUCT TABLE */}
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Product Name</th>
                <th>Category</th>
                <th>Price</th>
                <th>Availability</th>
                <th>Actions</th>
              </tr>
            </thead>

            <tbody>
              {loading ? (
                <tr>
                  <td
                    colSpan="5"
                    className="empty-state"
                  >
                    Loading products...
                  </td>
                </tr>
              ) : filteredProducts.length > 0 ? (
                filteredProducts.map((product) => (
                  <tr key={product.id}>
                    <td>{product.name}</td>

                    <td>
                      {categoryName(product.category_id)}
                    </td>

                    <td>
                      ₱{Number(product.price).toFixed(2)}
                    </td>

                    <td>
                      <span
                        className={`status-badge ${
                          product.is_available
                            ? "active"
                            : "inactive"
                        }`}
                      >
                        {product.is_available
                          ? "Available"
                          : "Unavailable"}
                      </span>
                    </td>

                    <td>
                      <div className="action-buttons">
                        <button
                          type="button"
                          className="edit-button"
                          title="Edit product"
                          onClick={() =>
                            openEdit(product)
                          }
                        >
                          <Pencil size={16} />
                        </button>

                        <button
                          type="button"
                          className="delete-button"
                          title="Delete product"
                          onClick={() =>
                            deleteProduct(product.id)
                          }
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td
                    colSpan="5"
                    className="empty-state"
                  >
                    No products to display.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* ADD / EDIT PRODUCT MODAL */}
      {showModal && (
        <div className="modal-overlay">
          <div className="modal">
            {/* MODAL HEADER */}
            <div className="modal-header">
              <h2>
                {editing !== null
                  ? "Edit Product"
                  : "Add Product"}
              </h2>

              <button
                type="button"
                className="close-button"
                onClick={closeModal}
                disabled={saving}
              >
                <X size={23} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              {/* MODAL ERROR */}
              {modalError && (
                <div className="error-message">
                  {modalError}
                </div>
              )}

              {/* PRODUCT NAME */}
              <div className="form-group">
                <label>Product Name</label>

                <input
                  type="text"
                  value={form.name}
                  onChange={(e) =>
                    handleChange(
                      "name",
                      e.target.value
                    )
                  }
                  placeholder="Enter product name"
                  required
                />
              </div>

              {/* CATEGORY */}
              <div className="form-group">
                <label>Category</label>

                <select
                  value={form.category_id}
                  onChange={(e) =>
                    handleChange(
                      "category_id",
                      e.target.value
                    )
                  }
                  required
                >
                  <option value="">
                    Select Category
                  </option>

                  {categories.map((item) => (
                    <option
                      key={item.id}
                      value={String(item.id)}
                    >
                      {item.name}
                    </option>
                  ))}
                </select>

                {categories.length === 0 && (
                  <small>
                    No categories available.
                    Please check the category API.
                  </small>
                )}
              </div>

              {/* DESCRIPTION */}
              <div className="form-group">
                <label>Description</label>

                <textarea
                  rows={3}
                  value={form.description}
                  onChange={(e) =>
                    handleChange(
                      "description",
                      e.target.value
                    )
                  }
                  placeholder="Enter product description"
                />
              </div>

              {/* PRICE */}
              <div className="form-group">
                <label>Price (PHP)</label>

                <input
                  type="number"
                  min="0"
                  step="0.01"
                  value={form.price}
                  onChange={(e) =>
                    handleChange(
                      "price",
                      e.target.value
                    )
                  }
                  placeholder="0.00"
                  required
                />
              </div>

              {/* AVAILABILITY */}
              <div className="checkbox-field">
                <input
                  id="availability"
                  type="checkbox"
                  checked={form.is_available}
                  onChange={(e) =>
                    handleChange(
                      "is_available",
                      e.target.checked
                    )
                  }
                />

                <label htmlFor="availability">
                  Available for ordering
                </label>
              </div>

              {/* MODAL BUTTONS */}
              <div className="modal-actions">
                <button
                  type="button"
                  className="secondary-button"
                  onClick={closeModal}
                  disabled={saving}
                >
                  Cancel
                </button>

                <button
                  type="submit"
                  className="primary-button"
                  disabled={
                    saving || categories.length === 0
                  }
                >
                  {saving
                    ? "Saving..."
                    : editing !== null
                    ? "Update Product"
                    : "Save Product"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
