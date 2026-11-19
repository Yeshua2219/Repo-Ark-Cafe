import { useEffect, useState, useCallback } from "react";
import { Plus, Search, Pencil, Trash2, X } from "lucide-react";
import api from "../services/api";
import "../styles/products.css";

const initialForm = {
  name: "",
  category_id: "",
  description: "",
  price: "",
  is_available: true,
};

export default function Products() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [form, setForm] = useState(initialForm);
  const [editing, setEditing] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const loadProducts = useCallback(async () => {
    try {
      const [productResponse, categoryResponse] = await Promise.all([
        api.get("/admin/products"),
        api.get("/categories"),
      ]);

      setProducts(productResponse.data);
      setCategories(categoryResponse.data);
      setError("");
    } catch {
      setError("Unable to load products and categories.");
    }
  }, []);

  useEffect(() => {
    loadProducts();
  }, [loadProducts]);

  const openAdd = () => {
    setEditing(null);
    setForm(initialForm);
    setShowModal(true);
  };

  const openEdit = (product) => {
    setEditing(product.id);

    setForm({
      name: product.name,
      category_id: product.category_id,
      description: product.description || "",
      price: product.price,
      is_available: product.is_available,
    });

    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError("");

    const payload = {
      ...form,
      name: form.name.trim(),
      price: Number(form.price),
    };

    try {
      if (editing !== null) {
        await api.put(`/admin/products/${editing}`, payload);
      } else {
        await api.post("/admin/products", payload);
      }

      setShowModal(false);
      await loadProducts();
    } catch (err) {
      setError(err.response?.data?.message || "Unable to save product.");
    } finally {
      setSaving(false);
    }
  };

  const deleteProduct = async (id) => {
    if (!window.confirm("Are you sure you want to remove this product?")) {
      return;
    }

    try {
      await api.delete(`/admin/products/${id}`);
      await loadProducts();
    } catch (err) {
      setError(err.response?.data?.message || "Unable to delete product.");
    }
  };

  const filteredProducts = products.filter((product) => {
    const matchesSearch = product.name
      .toLowerCase()
      .includes(search.toLowerCase());

    const matchesCategory =
      !category || String(product.category_id) === category;

    return matchesSearch && matchesCategory;
  });

  const categoryName = (id) =>
    categories.find((item) => String(item.id) === String(id))?.name ||
    "Uncategorized";

  return (
    <div>
      <div className="page-heading">
        <h1>Product Management</h1>
        <p>Manage ARK Cafe food and beverages.</p>
      </div>

      {error && <div className="error-message">{error}</div>}

      <section className="panel">
        <div className="toolbar">
          <div className="search-box">
            <Search size={19} />

            <input
              placeholder="Search products..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
          >
            <option value="">All Categories</option>

            {categories.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>

          <button className="primary-button" onClick={openAdd}>
            <Plus size={18} /> Add Product
          </button>
        </div>

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
              {filteredProducts.map((product) => (
                <tr key={product.id}>
                  <td>{product.name}</td>
                  <td>{categoryName(product.category_id)}</td>
                  <td>₱{Number(product.price).toFixed(2)}</td>

                  <td>
                    <span
                      className={`status-badge ${
                        product.is_available ? "active" : "inactive"
                      }`}
                    >
                      {product.is_available ? "Available" : "Unavailable"}
                    </span>
                  </td>

                  <td>
                    <div className="action-buttons">
                      <button
                        className="edit-button"
                        title="Edit product"
                        onClick={() => openEdit(product)}
                      >
                        <Pencil size={16} />
                      </button>

                      <button
                        className="delete-button"
                        title="Delete product"
                        onClick={() => deleteProduct(product.id)}
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}

              {!filteredProducts.length && (
                <tr>
                  <td colSpan="5" className="empty-state">
                    No products to display.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {showModal && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-header">
              <h2>{editing !== null ? "Edit Product" : "Add Product"}</h2>

              <button
                className="close-button"
                onClick={() => setShowModal(false)}
              >
                <X size={23} />
              </button>
            </div>

            <form onSubmit={handleSubmit}>
              {error && <div className="error-message">{error}</div>}

              <div className="form-group">
                <label>Product Name</label>
                <input
                  value={form.name}
                  onChange={(e) =>
                    setForm({ ...form, name: e.target.value })
                  }
                  required
                />
              </div>

              <div className="form-group">
                <label>Category</label>

                <select
                  value={form.category_id}
                  onChange={(e) =>
                    setForm({ ...form, category_id: e.target.value })
                  }
                  required
                >
                  <option value="">Select Category</option>

                  {categories.map((item) => (
                    <option key={item.id} value={item.id}>
                      {item.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Description</label>

                <textarea
                  rows="3"
                  value={form.description}
                  onChange={(e) =>
                    setForm({ ...form, description: e.target.value })
                  }
                />
              </div>

              <div className="form-group">
                <label>Price (PHP)</label>

                <input
                  type="number"
                  min="0"
                  step="0.01"
                  value={form.price}
                  onChange={(e) =>
                    setForm({ ...form, price: e.target.value })
                  }
                  required
                />
              </div>

              <div className="checkbox-field">
                <input
                  id="availability"
                  type="checkbox"
                  checked={form.is_available}
                  onChange={(e) =>
                    setForm({ ...form, is_available: e.target.checked })
                  }
                />

                <label htmlFor="availability">
                  Available for ordering
                </label>
              </div>

              <div className="modal-actions">
                <button
                  type="button"
                  className="secondary-button"
                  onClick={() => setShowModal(false)}
                >
                  Cancel
                </button>

                <button
                  type="submit"
                  className="primary-button"
                  disabled={saving}
                >
                  {saving ? "Saving..." : "Save Product"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}