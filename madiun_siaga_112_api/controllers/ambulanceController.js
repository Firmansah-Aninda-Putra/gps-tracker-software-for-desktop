// controllers/ambulanceController.js
const pool = require('../config/db');

exports.getLocations = async (req, res) => {
  try {
    const [locations] = await pool.query(
      'SELECT * FROM ambulance_locations ORDER BY timestamp DESC LIMIT 10'
    );
    res.status(200).json(locations);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude, status } = req.body;
    
    const [result] = await pool.query(
      'INSERT INTO ambulance_locations (latitude, longitude, status) VALUES (?, ?, ?)',
      [latitude, longitude, status]
    );
    
    res.status(200).json({
      message: 'Lokasi berhasil diperbarui',
      locationId: result.insertId
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};