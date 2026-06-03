const { validateInspectionPayload } = require('../utils/validateInspection');

const inspectionValidationMiddleware = (req, res, next) => {
  if (req.method === 'POST' || req.method === 'PUT') {
    // For PUT updates, only validate fields that are actually being updated
    if (req.method === 'PUT' && Object.keys(req.body).length === 0) {
      return res.status(400).json({ error: "Update body cannot be empty." });
    }
    
    // Run validation checks for creations
    if (req.method === 'POST') {
      const { isValid, errors } = validateInspectionPayload(req.body);
      if (!isValid) {
        return res.status(400).json({ error: "Validation Failed", details: errors });
      }
    }
  }
  next();
};

module.exports = inspectionValidationMiddleware;
