const express = require('express');
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Helper untuk format URL audio agar diputar via proxy backend (bebas CORS di Web & Mobile)
function formatSong(song, req) {
  const host = req.get('host');
  const protocol = req.protocol;
  return {
    ...song,
    cover_url: song.cover_url ? song.cover_url.trim() : null,
    audio_url: `${protocol}://${host}/api/songs/${song.id}/stream`,
  };
}

// =====================
// GET /api/songs
// Ambil semua lagu dengan info artist & album
// =====================
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.id, s.title, s.duration, s.audio_url, s.cover_url, s.play_count,
             a.name AS artist_name, a.id AS artist_id,
             al.title AS album_title, al.id AS album_id
      FROM songs s
      LEFT JOIN artists a ON s.artist_id = a.id
      LEFT JOIN albums al ON s.album_id = al.id
      ORDER BY s.play_count DESC
    `);
    const formatted = result.rows.map((song) => formatSong(song, req));
    res.json(formatted);
  } catch (err) {
    console.error('Error get songs:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// POST /api/songs
// Menambahkan lagu baru ke database
// =====================
router.post('/', async (req, res) => {
  const { title, artist_id, album_id, duration, audio_url, cover_url } = req.body;

  if (!title || !audio_url) {
    return res.status(400).json({ message: 'Judul (title) dan URL audio (audio_url) wajib diisi' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO songs (title, artist_id, album_id, duration, audio_url, cover_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [title, artist_id || null, album_id || null, duration || 0, audio_url, cover_url || null]
    );

    res.status(201).json({
      message: 'Lagu berhasil ditambahkan',
      song: formatSong(result.rows[0], req),
    });
  } catch (err) {
    console.error('Error add song:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// GET /api/songs/search?q=keyword
// Cari lagu berdasarkan judul atau nama artist
// =====================
router.get('/search', async (req, res) => {
  const { q } = req.query;
  if (!q) return res.json([]);

  try {
    const result = await pool.query(
      `
      SELECT s.id, s.title, s.duration, s.audio_url, s.cover_url, s.play_count,
             a.name AS artist_name, a.id AS artist_id,
             al.title AS album_title, al.id AS album_id
      FROM songs s
      LEFT JOIN artists a ON s.artist_id = a.id
      LEFT JOIN albums al ON s.album_id = al.id
      WHERE s.title ILIKE $1 OR a.name ILIKE $1
      ORDER BY s.play_count DESC
    `,
      [`%${q}%`]
    );
    const formatted = result.rows.map((song) => formatSong(song, req));
    res.json(formatted);
  } catch (err) {
    console.error('Error search songs:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// GET /api/songs/liked/all  (protected)
// Ambil semua lagu yang di-like user (letakkan sebelum /:id)
// =====================
router.get('/liked/all', authMiddleware, async (req, res) => {
  const userId = req.user.id;
  try {
    const result = await pool.query(
      `
      SELECT s.id, s.title, s.duration, s.audio_url, s.cover_url,
             a.name AS artist_name, a.id AS artist_id,
             ls.liked_at
      FROM liked_songs ls
      JOIN songs s ON ls.song_id = s.id
      LEFT JOIN artists a ON s.artist_id = a.id
      WHERE ls.user_id = $1
      ORDER BY ls.liked_at DESC
    `,
      [userId]
    );
    const formatted = result.rows.map((song) => formatSong(song, req));
    res.json(formatted);
  } catch (err) {
    console.error('Error get liked songs:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// GET /api/songs/:id/stream
// Streaming proxy audio langsung pipa chunk (instant play, support Range/206)
// =====================
router.get('/:id/stream', async (req, res) => {
  try {
    const result = await pool.query('SELECT audio_url FROM songs WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0 || !result.rows[0].audio_url) {
      return res.status(404).send('Audio tidak ditemukan');
    }

    const audioUrl = result.rows[0].audio_url;
    const fetchHeaders = {};
    if (req.headers.range) {
      fetchHeaders['range'] = req.headers.range;
    }

    const response = await fetch(audioUrl, { headers: fetchHeaders });
    if (!response.ok && response.status !== 206) {
      return res.status(response.status).send('Gagal memuat file audio');
    }

    res.status(response.status);
    res.setHeader('Content-Type', response.headers.get('content-type') || 'audio/mpeg');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Accept-Ranges', 'bytes');

    const contentLength = response.headers.get('content-length');
    if (contentLength) res.setHeader('Content-Length', contentLength);

    const contentRange = response.headers.get('content-range');
    if (contentRange) res.setHeader('Content-Range', contentRange);

    const { Readable } = require('stream');
    const audioStream = Readable.fromWeb(response.body);

    audioStream.on('error', () => {
      // Client aborted / skipped audio, safely ignore
    });

    req.on('close', () => {
      try {
        audioStream.destroy();
      } catch (_) {}
    });

    audioStream.pipe(res);
  } catch (err) {
    console.error('Error stream audio:', err.message);
    if (!res.headersSent) {
      res.status(500).send('Streaming error');
    }
  }
});

// =====================
// GET /api/songs/:id
// Detail satu lagu
// =====================
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT s.id, s.title, s.duration, s.audio_url, s.cover_url, s.play_count,
             a.name AS artist_name, a.id AS artist_id,
             al.title AS album_title, al.id AS album_id
      FROM songs s
      LEFT JOIN artists a ON s.artist_id = a.id
      LEFT JOIN albums al ON s.album_id = al.id
      WHERE s.id = $1
    `,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Lagu tidak ditemukan' });
    }
    res.json(formatSong(result.rows[0], req));
  } catch (err) {
    console.error('Error get song detail:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// POST /api/songs/:id/play
// Increment play count
// =====================
router.post('/:id/play', async (req, res) => {
  try {
    await pool.query('UPDATE songs SET play_count = play_count + 1 WHERE id = $1', [req.params.id]);
    res.json({ message: 'Play count updated' });
  } catch (err) {
    console.error('Error update play count:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// POST /api/songs/:id/like  (protected)
// Like / Unlike lagu
// =====================
router.post('/:id/like', authMiddleware, async (req, res) => {
  const userId = req.user.id;
  const songId = req.params.id;

  try {
    const existing = await pool.query(
      'SELECT id FROM liked_songs WHERE user_id = $1 AND song_id = $2',
      [userId, songId]
    );

    if (existing.rows.length > 0) {
      await pool.query('DELETE FROM liked_songs WHERE user_id = $1 AND song_id = $2', [userId, songId]);
      return res.json({ liked: false, message: 'Lagu dihapus dari favorit' });
    } else {
      await pool.query('INSERT INTO liked_songs (user_id, song_id) VALUES ($1, $2)', [userId, songId]);
      return res.json({ liked: true, message: 'Lagu ditambahkan ke favorit' });
    }
  } catch (err) {
    console.error('Error like song:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
