 const express = require('express');
 const app = express();
 require('dotenv').config();
 
 app.use(express.json());
 // ✅ Log response time for every request
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.url} - ${res.statusCode} - ${duration}ms`);
  });
  next();
});
 
 const shipmentsRouter = require('./routes/shipments');
 app.use('/api/shipments', shipmentsRouter);
 
 const PORT = process.env.PORT || 3000;
 app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
