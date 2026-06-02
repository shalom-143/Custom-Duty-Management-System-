const TraderService = require('../services/traderService');

class TraderController {
  static async create(req, res) {
    try {
      const trader = await TraderService.createTrader(req.body);
      res.status(201).json({ success: true, data: trader });
    } catch (error) {
      res.status(400).json({ success: false, message: error.message });
    }
  }

  static async getById(req, res) {
    try {
      const trader = await TraderService.getTraderById(req.params.id);
      res.status(200).json({ success: true, data: trader });
    } catch (error) {
      res.status(404).json({ success: false, message: error.message });
    }
  }

  static async getAll(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 50;
      const traders = await TraderService.getAllTraders(page, limit);
      res.status(200).json({ success: true, data: traders });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }

  static async update(req, res) {
    try {
      const trader = await TraderService.updateTrader(req.params.id, req.body);
      res.status(200).json({ success: true, data: trader });
    } catch (error) {
      res.status(400).json({ success: false, message: error.message });
    }
  }

  static async delete(req, res) {
    try {
      const result = await TraderService.deleteTrader(req.params.id);
      res.status(200).json({ success: true, message: result.message });
    } catch (error) {
      res.status(404).json({ success: false, message: error.message });
    }
  }
}

module.exports = TraderController;