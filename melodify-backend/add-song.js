/**
 * Script Pembantu untuk Menambahkan Lagu ke Database Melodify
 * Cara pakai:
 *   node add-song.js "Judul Lagu" "Nama Artis" "https://audio-url.mp3" "https://cover-url.jpg" 210
 * Atau jalankan tanpa argumen untuk melihat petunjuk dan contoh.
 */
const pool = require('./db');

async function addSong() {
  const args = process.argv.slice(2);

  if (args.length < 3) {
    console.log('🎵 Melodify - Tambah Lagu');
    console.log('----------------------------------------------------');
    console.log('Gunakan perintah:');
    console.log('  node add-song.js "<Judul Lagu>" "<Nama Artis>" "<Audio URL (mp3)>" "[Cover URL]" "[Durasi Detik]"');
    console.log('\nContoh:');
    console.log('  node add-song.js "Hati-Hati di Jalan" "Tulus" "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3" "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4" 240');
    console.log('----------------------------------------------------');
    process.exit(0);
  }

  const [title, artistName, audioUrl, coverUrl = null, duration = 180] = args;

  try {
    // 1. Cari atau buat artis
    let artistRes = await pool.query('SELECT id FROM artists WHERE LOWER(name) = LOWER($1)', [artistName]);
    let artistId;

    if (artistRes.rows.length === 0) {
      console.log(`🎤 Artis '${artistName}' belum ada, membuat artis baru...`);
      const newArtist = await pool.query(
        'INSERT INTO artists (name, image_url) VALUES ($1, $2) RETURNING id',
        [artistName, coverUrl]
      );
      artistId = newArtist.rows[0].id;
    } else {
      artistId = artistRes.rows[0].id;
    }

    // 2. Masukkan lagu
    const songRes = await pool.query(
      `INSERT INTO songs (title, artist_id, duration, audio_url, cover_url)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, title, duration, audio_url, cover_url`,
      [title, artistId, parseInt(duration, 10) || 180, audioUrl, coverUrl]
    );

    const song = songRes.rows[0];
    console.log('✅ Lagu berhasil ditambahkan ke database!');
    console.log('----------------------------------------------------');
    console.log(`ID     : ${song.id}`);
    console.log(`Judul  : ${song.title}`);
    console.log(`Artis  : ${artistName} (ID: ${artistId})`);
    console.log(`Durasi : ${song.duration} detik`);
    console.log(`Audio  : ${song.audio_url}`);
    console.log(`Cover  : ${song.cover_url || '-'}`);
    console.log('----------------------------------------------------');
  } catch (err) {
    console.error('❌ Gagal menambahkan lagu:', err.message);
  } finally {
    await pool.end();
    process.exit(0);
  }
}

addSong();
