const express = require('express');
const router = express.Router();
const GoodsController = require('../controllers/goodsController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.post('/', GoodsController.create);
router.get('/', GoodsController.getAll);
router.get('/:id', GoodsController.getById);
router.put('/:id', GoodsController.update);
router.delete('/:id', GoodsController.delete);

module.exports = router;
