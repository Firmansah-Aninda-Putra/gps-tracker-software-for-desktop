// middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const authMiddleware = async (req, res, next) => {
  try {
    // Periksa header Authorization
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Tidak ada token' });
    }
    
    const token = authHeader.split(' ')[1];
    
    // Verifikasi token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Cek apakah user masih ada di database
    const [users] = await pool.query(
      'SELECT id, name, phone, is_admin FROM users WHERE id = ?',
      [decoded.id]
    );
    
    if (users.length === 0) {
      return res.status(401).json({ message: 'User tidak ditemukan' });
    }
    
    // Tambahkan user ke objek request
    req.user = users[0];
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token tidak valid' });
  }
};

module.exports = authMiddleware;