/**
 * Custom Duty Management System (CDMS)
 * Customs Officer Controller
 */

const DBModels = require('../models/dbModels');

exports.createOfficer = async (req, res, next) => {
  try {
    const officer = await DBModels.createOfficer(req.body);
    res.status(201).json({ success: true, data: officer });
  } catch (err) {
    next(err);
  }
};

exports.getAllOfficers = async (req, res, next) => {
  try {
    const officers = await DBModels.getAllOfficers();
    res.status(200).json({ success: true, count: officers.length, data: officers });
  } catch (err) {
    next(err);
  }
};

exports.getOfficerById = async (req, res, next) => {
  try {
    const officer = await DBModels.getOfficerById(req.params.id);
    if (!officer) {
      return res.status(404).json({ success: false, message: 'Customs Officer not found' });
    }
    res.status(200).json({ success: true, data: officer });
  } catch (err) {
    next(err);
  }
};

exports.updateOfficer = async (req, res, next) => {
  try {
    const officer = await DBModels.updateOfficer(req.params.id, req.body);
    if (!officer) {
      return res.status(404).json({ success: false, message: 'Customs Officer not found' });
    }
    res.status(200).json({ success: true, data: officer });
  } catch (err) {
    next(err);
  }
};

exports.deleteOfficer = async (req, res, next) => {
  try {
    const officer = await DBModels.deleteOfficer(req.params.id);
    if (!officer) {
      return res.status(404).json({ success: false, message: 'Customs Officer not found' });
    }
    res.status(200).json({ success: true, data: officer, message: 'Customs Officer deleted successfully' });
  } catch (err) {
    next(err);
  }
};
