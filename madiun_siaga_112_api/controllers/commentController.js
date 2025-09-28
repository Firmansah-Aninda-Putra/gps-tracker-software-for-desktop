// controllers/commentController.js
const pool = require('../config/db');

exports.getComments = async (req, res) => {
  try {
    const [comments] = await pool.query(`
      SELECT c.*, u.name as user_name 
      FROM comments c
      JOIN users u ON c.user_id = u.id
      ORDER BY c.timestamp DESC
    `);
    res.status(200).json(comments);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.addComment = async (req, res) => {
  try {
    const { content } = req.body;
    const userId = req.user.id; // Dari middleware auth
    
    const [result] = await pool.query(
      'INSERT INTO comments (user_id, content) VALUES (?, ?)',
      [userId, content]
    );
    
    // Ambil komentar yang baru dibuat bersama dengan nama user
    const [newComments] = await pool.query(`
      SELECT c.*, u.name as user_name 
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.id = ?
    `, [result.insertId]);
    
    res.status(201).json(newComments[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};