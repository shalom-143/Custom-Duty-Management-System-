const TraderModel = require('../models/traderModel');

class TraderService {
  static async createTrader(traderData) {
    const required = ['TraderID', 'TraderName', 'Address', 'Phone', 'Email', 'Tin', 'TraderType'];
    const missing = required.filter(field => !traderData[field]);
    if (missing.length > 0) throw new Error(`Missing required fields: ${missing.join(', ')}`);

    try {
      return await TraderModel.create(traderData);
    } catch (error) {
      if (error.code === '23505') {
        throw new Error('A trader with this Email or TIN already exists');
      }
      throw error;
    }
  }

  static async getTraderById(id) {
    const trader = await TraderModel.findById(id);
    if (!trader) throw new Error('Trader not found');
    return trader;
  }

  static async getAllTraders(page = 1, limit = 50) {
    const offset = (page - 1) * limit;
    return await TraderModel.findAll(limit, offset);
  }

  static async updateTrader(id, traderData) {
    const existing = await TraderModel.findById(id);
    if (!existing) throw new Error('Trader not found');

    try {
      const updated = await TraderModel.update(id, traderData);
      return updated;
    } catch (error) {
      if (error.code === '23505') {
        throw new Error('Another trader already uses this Email or TIN');
      }
      throw error;
    }
  }

  static async deleteTrader(id) {
    const deleted = await TraderModel.delete(id);
    if (!deleted) throw new Error('Trader not found');
    return { message: 'Trader deleted successfully' };
  }
}

module.exports = TraderService;