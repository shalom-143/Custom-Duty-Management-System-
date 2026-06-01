 const express = require('express');
 const app = express();
 require('dotenv').config();
 
 app.use(express.json());
 
 const shipmentsRouter = require('./routes/shipments');
 app.use('/api/shipments', shipmentsRouter);
 
 const PORT = process.env.PORT || 3000;
 app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
