// server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const ambulanceRoutes = require('./routes/ambulanceRoutes');
const commentRoutes = require('./routes/commentRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/', authRoutes);
app.use('/ambulance', ambulanceRoutes);
app.use('/comments', commentRoutes);

// Test route
app.get('/', (req, res) => {
  res.send('Madiun Siaga 112 API berhasil berjalan');
});

// Start server
app.listen(PORT, () => {
  console.log(`Server berjalan di port ${PORT}`);
});