// controllers/authController.js
const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

exports.login = async (req, res) => {
  try {
    const { phone, password } = req.body;
    
    // Cari user berdasarkan nomor telepon
    const [users] = await pool.query(
      'SELECT * FROM users WHERE phone = ?', 
      [phone]
    );
    
    if (users.length === 0) {
      return res.status(401).json({ message: 'Nomor telepon atau password salah' });
    }
    
    const user = users[0];
    
    // Bandingkan password
    const passwordMatch = await bcrypt.compare(password, user.password);
    
    if (!passwordMatch) {
      return res.status(401).json({ message: 'Nomor telepon atau password salah' });
    }
    
    // Buat token JWT
    const token = jwt.sign(
      { id: user.id, phone: user.phone, isAdmin: user.is_admin === 1 },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    // Hapus password dari respons
    delete user.password;
    
    res.status(200).json({
      message: 'Login berhasil',
      token,
      user
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.register = async (req, res) => {
  try {
    const { name, address, phone, password } = req.body;
    
    // Cek apakah nomor telepon sudah terdaftar
    const [existingUsers] = await pool.query(
      'SELECT * FROM users WHERE phone = ?', 
      [phone]
    );
    
    if (existingUsers.length > 0) {
      return res.status(400).json({ message: 'Nomor telepon sudah terdaftar' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Simpan user baru
    const [result] = await pool.query(
      'INSERT INTO users (name, address, phone, password) VALUES (?, ?, ?, ?)',
      [name, address, phone, hashedPassword]
    );
    
    const userId = result.insertId;
    
    // Ambil data user yang baru dibuat
    const [newUsers] = await pool.query(
      'SELECT id, name, address, phone, is_admin FROM users WHERE id = ?',
      [userId]
    );
    
    res.status(201).json({
      message: 'Registrasi berhasil',
      user: newUsers[0]
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};