const express = require('express');
const authMiddleware = require('../middleware/auth');
const categoryService = require('../services/categoryService');

const router = express.Router();

// GET /api/categories - Get all categories for user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const categories = await categoryService.getAll(req.userId);
    res.json({ code: 0, data: categories });
  } catch (err) {
    res.status(500).json({ code: 500, msg: err.message });
  }
});

// POST /api/categories - Create a custom category
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { name, type, icon } = req.body;

    if (!name || !type) {
      return res.status(400).json({ code: 400, msg: 'Name and type are required' });
    }

    if (type !== 'income' && type !== 'expense') {
      return res.status(400).json({ code: 400, msg: 'Type must be income or expense' });
    }

    const category = await categoryService.create(req.userId, { name, type, icon });
    res.json({ code: 0, data: category });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// PUT /api/categories/:id - Update a category
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const { name, type, icon } = req.body;
    const updated = await categoryService.update(req.params.id, req.userId, { name, type, icon });

    if (!updated) {
      return res.status(404).json({ code: 404, msg: 'Category not found or cannot be modified' });
    }

    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

// DELETE /api/categories/:id - Delete a category
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const deleted = await categoryService.remove(req.params.id, req.userId);

    if (!deleted) {
      return res.status(404).json({ code: 404, msg: 'Category not found or cannot be deleted' });
    }

    res.json({ code: 0, data: true });
  } catch (err) {
    res.status(400).json({ code: 400, msg: err.message });
  }
});

module.exports = router;