const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'melodify_secret';

// =====================
// POST /api/auth/register
// =====================
router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ message: 'Semua field wajib diisi' });
  }

  try {
    // Cek apakah email sudah dipakai
    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ message: 'Email sudah terdaftar' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Simpan user baru
    const result = await pool.query(
      'INSERT INTO users (name, email, password) VALUES ($1, $2, $3) RETURNING id, name, email',
      [name, email, hashedPassword]
    );

    const user = result.rows[0];

    // Buat token JWT
    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      message: 'Registrasi berhasil',
      token,
      user: { id: user.id, name: user.name, email: user.email },
    });
  } catch (err) {
    console.error('Error register:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// POST /api/auth/login
// =====================
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email dan password wajib diisi' });
  }

  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Email atau password salah' });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Email atau password salah' });
    }

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

    res.json({
      message: 'Login berhasil',
      token,
      user: { id: user.id, name: user.name, email: user.email, profile_image: user.profile_image },
    });
  } catch (err) {
    console.error('Error login:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// GET /api/auth/me (protected)
// =====================
const authMiddleware = require('../middleware/auth');
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, username, email, bio, profile_image, created_at FROM users WHERE id = $1',
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error get profile:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// =====================
// PUT /api/auth/profile (protected)
// =====================
router.put('/profile', authMiddleware, async (req, res) => {
  const { name, username, bio, profile_image } = req.body;
  try {
    const result = await pool.query(
      `UPDATE users 
       SET name = COALESCE($1, name),
           username = COALESCE($2, username),
           bio = COALESCE($3, bio),
           profile_image = COALESCE($4, profile_image)
       WHERE id = $5
       RETURNING id, name, username, email, bio, profile_image`,
      [name, username, bio, profile_image, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    res.json({
      message: 'Profil berhasil diperbarui',
      user: result.rows[0],
    });
  } catch (err) {
    console.error('Error update profile:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
