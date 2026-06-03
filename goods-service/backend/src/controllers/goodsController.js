const Goods = require('../models/Goods');

class GoodsController {
    static async create(req, res) {
        try {
            const goods = await Goods.create(req.body);
            res.status(201).json({ success: true, data: goods });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    static async getAll(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 20;
            const result = await Goods.findAll(page, limit);
            res.json({ success: true, ...result });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    static async getById(req, res) {
        try {
            const goods = await Goods.findById(req.params.id);
            if (!goods) {
                return res.status(404).json({ success: false, error: 'Goods not found' });
            }
            res.json({ success: true, data: goods });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    static async update(req, res) {
        try {
            const goods = await Goods.update(req.params.id, req.body);
            if (!goods) {
                return res.status(404).json({ success: false, error: 'Goods not found' });
            }
            res.json({ success: true, data: goods });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    static async delete(req, res) {
        try {
            const goods = await Goods.delete(req.params.id);
            if (!goods) {
                return res.status(404).json({ success: false, error: 'Goods not found' });
            }
            res.json({ success: true, message: 'Goods deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = GoodsController;
