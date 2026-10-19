-- ===================================================
-- MELODIFY DATABASE SCHEMA
-- PostgreSQL Migration Script
-- ===================================================

CREATE DATABASE melodify_db;
\c melodify_db;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  username VARCHAR(100),
  email VARCHAR(150) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  bio TEXT DEFAULT '',
  profile_image VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Artists table
CREATE TABLE IF NOT EXISTS artists (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  bio TEXT,
  image_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Albums table
CREATE TABLE IF NOT EXISTS albums (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  artist_id INT REFERENCES artists(id) ON DELETE CASCADE,
  cover_url VARCHAR(255),
  release_year INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Songs table
CREATE TABLE IF NOT EXISTS songs (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  artist_id INT REFERENCES artists(id) ON DELETE SET NULL,
  album_id INT REFERENCES albums(id) ON DELETE SET NULL,
  duration INT DEFAULT 0, -- durasi dalam detik
  audio_url VARCHAR(255),
  cover_url VARCHAR(255),
  play_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Playlists table
CREATE TABLE IF NOT EXISTS playlists (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  cover_url VARCHAR(255),
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Playlist songs (many-to-many)
CREATE TABLE IF NOT EXISTS playlist_songs (
  id SERIAL PRIMARY KEY,
  playlist_id INT REFERENCES playlists(id) ON DELETE CASCADE,
  song_id INT REFERENCES songs(id) ON DELETE CASCADE,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(playlist_id, song_id)
);

-- Liked songs table
CREATE TABLE IF NOT EXISTS liked_songs (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  song_id INT REFERENCES songs(id) ON DELETE CASCADE,
  liked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, song_id)
);

-- ===================================================
-- SEED DATA (Contoh data awal)
-- ===================================================

-- Insert Artists
INSERT INTO artists (name, bio, image_url) VALUES
  ('The Weeknd', 'Canadian singer-songwriter and record producer.', 'https://i.scdn.co/image/ab6761610000e5eb214f3cf1cbe7139c1e26ffbb'),
  ('Taylor Swift', 'American singer-songwriter known for narrative songwriting.', 'https://i.scdn.co/image/ab6761610000e5eb5a00969a4698c3132a15fbb0'),
  ('Dua Lipa', 'British-Albanian singer and songwriter.', 'https://i.scdn.co/image/ab6761610000e5eb1ba8fc5f5c73e7e9284b55e5'),
  ('Ed Sheeran', 'English singer-songwriter and musician.', 'https://i.scdn.co/image/ab6761610000e5eb3bcef85e105dfc42399ef0ba'),
  ('Billie Eilish', 'American singer-songwriter known for her whispery vocals.', 'https://i.scdn.co/image/ab6761610000e5eb01dfa91b2d0ec7d2c00e0e16');

-- Insert Albums
INSERT INTO albums (title, artist_id, cover_url, release_year) VALUES
  ('After Hours', 1, 'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36', 2020),
  ('Midnights', 2, 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5', 2022),
  ('Future Nostalgia', 3, 'https://i.scdn.co/image/ab67616d0000b2734bc66095f8a70bc4e6593f4f', 2020),
  ('Divide', 4, 'https://i.scdn.co/image/ab67616d0000b273ba5db46f4b838ef6027e6f96', 2017),
  ('Happier Than Ever', 5, 'https://i.scdn.co/image/ab67616d0000b273f4a6ed28e66e5d97a3adb2aa', 2021);

-- Insert Songs
INSERT INTO songs (title, artist_id, album_id, duration, audio_url, cover_url, play_count) VALUES
  ('Blinding Lights', 1, 1, 200, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36', 3500000),
  ('Save Your Tears', 1, 1, 215, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', 'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36', 2800000),
  ('Anti-Hero', 2, 2, 201, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5', 4200000),
  ('Levitate', 2, 2, 183, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5', 1900000),
  ('Levitating', 3, 3, 203, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', 'https://i.scdn.co/image/ab67616d0000b2734bc66095f8a70bc4e6593f4f', 3100000),
  ('Don''t Start Now', 3, 3, 183, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', 'https://i.scdn.co/image/ab67616d0000b2734bc66095f8a70bc4e6593f4f', 2700000),
  ('Shape of You', 4, 4, 234, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', 'https://i.scdn.co/image/ab67616d0000b273ba5db46f4b838ef6027e6f96', 5000000),
  ('Perfect', 4, 4, 263, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', 'https://i.scdn.co/image/ab67616d0000b273ba5db46f4b838ef6027e6f96', 3800000),
  ('Happier Than Ever', 5, 5, 295, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', 'https://i.scdn.co/image/ab67616d0000b273f4a6ed28e66e5d97a3adb2aa', 2200000),
  ('Bad Guy', 5, 5, 194, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', 'https://i.scdn.co/image/ab67616d0000b273f4a6ed28e66e5d97a3adb2aa', 4500000);
