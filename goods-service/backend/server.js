require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const goodsRoutes = require('./src/routes/goodsRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use('/api/goods', goodsRoutes);

app.get('/health', (req, res) => {
    res.json({ status: 'OK', service: 'goods-service' });
});

app.listen(PORT, () => {
    console.log(`\n🚀 Goods Service running on port ${PORT}`);
    console.log(`📍 http://localhost:${PORT}/api/goods\n`);
});
