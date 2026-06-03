const jwt = require('jsonwebtoken');
require('dotenv').config();

const token = jwt.sign(
    { userId: 1, email: 'admin@example.com', role: 'ADMIN' },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
);

console.log('\n🔑 Your Token:\n');
console.log(token);
console.log('\n');
