const express = require('express');
const pool = require('../db');

const router = express.Router();

// =====================
// GET /api/artists
// Ambil semua artist
// =====================
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM artists ORDER BY name ASC');
    res.json(result.rows);
  } catch (err) {
    console.error('Error get artists:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// GET /api/artists/albums/all
// Ambil semua album (letakkan sebelum /:id)
// =====================
router.get('/albums/all', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT al.*, a.name AS artist_name 
      FROM albums al 
      LEFT JOIN artists a ON al.artist_id = a.id 
      ORDER BY al.release_year DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error('Error get albums:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// GET /api/artists/:id
// Detail artist + daftar lagunya
// =====================
router.get('/:id', async (req, res) => {
  try {
    const artistResult = await pool.query('SELECT * FROM artists WHERE id = $1', [req.params.id]);
    if (artistResult.rows.length === 0) {
      return res.status(404).json({ message: 'Artist tidak ditemukan' });
    }

    const artist = artistResult.rows[0];

    const songsResult = await pool.query(`
      SELECT s.id, s.title, s.duration, s.audio_url, s.cover_url, s.play_count,
             al.title AS album_title
      FROM songs s
      LEFT JOIN albums al ON s.album_id = al.id
      WHERE s.artist_id = $1
      ORDER BY s.play_count DESC
    `, [req.params.id]);

    artist.songs = songsResult.rows;
    res.json(artist);
  } catch (err) {
    console.error('Error get artist detail:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
