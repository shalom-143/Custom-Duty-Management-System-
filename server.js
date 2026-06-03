require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const inspectionRoutes = require('./src/routes/inspectionRoutes');

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/inspections', inspectionRoutes);

// Health Check Route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', module: 'Inspection Module' });
});

// 404 Handler
app.use('*', (req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(` Inspection Module is running on port ${PORT}`);
  console.log(` Health Check: http://localhost:${PORT}/health`);
});