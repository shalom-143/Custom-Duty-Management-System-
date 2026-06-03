const express = require('express');
const router = express.Router();
const {
  createInspection,
  getAllInspections,
  updateInspection,
  deleteInspection,
} = require('../controllers/inspectionController');

router.route('/')
  .post(createInspection)
  .get(getAllInspections);

router.route('/:id')
  .put(updateInspection)
  .delete(deleteInspection);

module.exports = router;
