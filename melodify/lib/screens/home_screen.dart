import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import 'player_screen.dart';
import 'profile_screen.dart';

/// jumlah baris per slide dan jumlah slide.
const int kRowsPerPage = 3;
const int kListenPages = 2;

const _bg = Color(0xFF121212);
const _green = Color(0xFF1DB954);
const _grey = Color(0xFFB3B3B3);

const _palette = [
  Color(0xFF3F51B5),
  Color(0xFFC62828),
  Color(0xFFEF6C00),
  Color(0xFF6D4C41),
  Color(0xFF9E9D24),
  Color(0xFF00897B),
  Color(0xFF8E24AA),
  Color(0xFF1E88E5),
];

Color _colorFor(int i) => _palette[i % _palette.length];

class _Mix {
  final String title;
  final Color color;
  final int startIndex; // lagu pertama yang diputar saat kartu diketuk
  const _Mix(this.title, this.color, this.startIndex);
}

const _mixes = [
  _Mix('Pop Mix', Color(0xFFF8A5D6), 0),
  _Mix('Mix 2020-an', Color(0xFFFF8A80), 4),
  _Mix('Indie Mix', Color(0xFFA5D6A7), 8),
  _Mix('Indo Hits', Color(0xFF90CAF9), 5),
  _Mix('Santai Malam', Color(0xFFFFCC80), 11),
];

class _Section {
  final String title;
  final List<int> songIndexes;
  const _Section(this.title, this.songIndexes);
}

const _extraSections = [
  _Section('Baru diputar', [3, 0, 7, 12, 9, 14]),
  _Section('Santai sore', [4, 6, 10, 2, 13, 5]),
  _Section('Throwback Indonesia', [8, 9, 10, 11, 1, 0]),
  _Section('Pilihan untukmu', [13, 14, 12, 7, 6, 3]),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ambil data dari backend ---
  List<Song> _songs = [];
  bool _isLoading = true;

  // ---state tampilan---
  int _navIndex = 0;
  int _nowIndex = 0; // lagu aktif di mini player
  bool _playing = false;

  final PageController _miniCtrl = PageController();
  final PageController _listenCtrl = PageController(viewportFraction: 0.94);

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _miniCtrl.dispose();
    _listenCtrl.dispose();
    super.dispose();
  }

  // Ambil semua lagu dari backend
  Future<void> _loadSongs() async {
    try {
      final songs = await SongService.getAllSongs();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // kalau lagu di backend lebih sedikit dari index preview,
  // index otomatis "muter" agar tidak error.
  Song _songAt(int i) => _songs[i % _songs.length];

  // ambil nama artis dari field artistname di models/song
  String _artistOf(Song s) => s.artistName;
  int _safe(int i) => i % _songs.length;

  // Putar lagu lewat PlayerProvider.
  void _playSong(int index) {
    final i = _safe(index);
    setState(() {
      _nowIndex = i;
      _playing = true;
    });
    if (_miniCtrl.hasClients) _miniCtrl.jumpToPage(i);
    context.read<PlayerProvider>().playSong(_songs[i], songList: _songs);
  }

  void _openPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadSongs,
          color: _green,
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: _buildBottom(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: [
          _buildTopBar(),
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator(color: _green)),
          ),
        ],
      );
    }

    if (_songs.isEmpty) {
      return ListView(
        children: [
          _buildTopBar(),
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: Text(
                'Belum ada lagu.\nTarik ke bawah untuk memuat ulang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _grey),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _buildTopBar(),
        _sectionTitle('Mix teratasmu'),
        _buildMixes(),
        _buildStartListening(),
        _buildRelated(),
        for (final s in _extraSections) ...[
          _sectionTitle(
            s.title,
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
          ),
          _buildSongCards(s.songIndexes),
        ],
      ],
    );
  }

  // ------------------------------------
  // Bagian atas (avatar dari data user)
  // ------------------------------------
  Widget _buildTopBar() {
    final user = context.watch<AuthProvider>().user;
    final initial = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : 'M';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, {EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ----------------
  // Mix Lagu teratas
  // ----------------
  Widget _buildMixes() {
    return SizedBox(
      height: 215,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _mixCard(_mixes[i]),
      ),
    );
  }

  // Subtitle mix dibuat dari nama artis lagu asli
  String _mixSubtitle(int start) {
    final artists = <String>[];
    for (int k = 0; k < 4; k++) {
      final a = _artistOf(_songAt(start + k));
      if (a.isNotEmpty && !artists.contains(a)) artists.add(a);
      if (artists.length == 3) break;
    }
    return '${artists.join(', ')}, dan lainnya';
  }

  Widget _mixCard(_Mix mix) {
    final song = _songAt(mix.startIndex);
    return GestureDetector(
      onTap: () => _playSong(mix.startIndex),
      child: SizedBox(
        width: 144,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 144,
                height: 144,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _cover(mix.color, 144, url: song.coverUrl),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 26,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 10),
                        color: mix.color,
                        child: Text(
                          mix.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mixSubtitle(mix.startIndex),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _grey, fontSize: 12.5, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------
  // Mulai mendengarkan Lagu
  // ------------------------
  Widget _buildStartListening() {
    final total = (kRowsPerPage * kListenPages).clamp(0, _songs.length);
    final all = List<int>.generate(total, (i) => i);
    final pages = <List<int>>[];
    for (int i = 0; i < all.length; i += kRowsPerPage) {
      pages.add(all.sublist(i, (i + kRowsPerPage).clamp(0, all.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 28, 16, 2),
          child: Text(
            'Nikmati sesi berdasarkan seleramu',
            style: TextStyle(color: _grey, fontSize: 13),
          ),
        ),
        _sectionTitle(
          'Mulai mendengarkan',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        ),
        SizedBox(
          height: kRowsPerPage * 64.0,
          child: PageView.builder(
            padEnds: false,
            controller: _listenCtrl,
            itemCount: pages.length,
            itemBuilder: (_, p) =>
                Column(children: pages[p].map(_trackRow).toList()),
          ),
        ),
      ],
    );
  }

  Widget _trackRow(int index) {
    final song = _songAt(index);
    final isCurrent = index == _nowIndex;
    return InkWell(
      onTap: () => _playSong(index),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: _cover(_colorFor(index), 50, url: song.coverUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? _green : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _artistOf(song),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: _grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // Bagian 2 : Lainnya seperti ...
  Widget _buildRelated() {
    final ref = _songAt(3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
          child: Row(
            children: [
              ClipOval(child: _cover(_colorFor(3), 50, url: ref.coverUrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lainnya seperti',
                      style: TextStyle(color: _grey, fontSize: 13),
                    ),
                    Text(
                      _artistOf(ref),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildSongCards(const [4, 5, 6, 7, 3, 12]),
      ],
    );
  }

  // Geser Slide Kanan Kiri Bagian 2
  Widget _buildSongCards(List<int> indexes, {bool withText = true}) {
    return SizedBox(
      height: withText ? 200 : 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: indexes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final idx = _safe(indexes[i]);
          final song = _songs[idx];
          return GestureDetector(
            onTap: () => _playSong(idx),
            child: SizedBox(
              width: 144,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _cover(_colorFor(idx), 144, url: song.coverUrl),
                  ),
                  if (withText) ...[
                    const SizedBox(height: 8),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _artistOf(song),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _grey, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Mini player (geser = lagu berikutnya/sebelumnya) + navbar
  Widget _buildBottom() {
    return Container(
      color: _bg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_songs.isNotEmpty)
              SizedBox(
                height: 60,
                child: PageView.builder(
                  controller: _miniCtrl,
                  itemCount: _songs.length,
                  onPageChanged: (i) {
                    // jumpToPage dari _playSong juga memicu callback ini,
                    // jadi cek dulu supaya tidak diputar dua kali.
                    if (i == _nowIndex) return;
                    _playSong(i);
                  },
                  itemBuilder: (_, i) => _miniCard(i),
                ),
              ),
            BottomNavigationBar(
              backgroundColor: _bg,
              type: BottomNavigationBarType.fixed,
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
              selectedItemColor: Colors.white,
              unselectedItemColor: _grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Cari',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music),
                  label: 'Library',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Buat'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCard(int index) {
    final song = _songs[index];
    return GestureDetector(
      onTap: _openPlayer, // ketuk mini player = buka layar pemutar penuh
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFF2A2A2A), _colorFor(index), 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _cover(_colorFor(index), 40, url: song.coverUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _artistOf(song),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.speaker_group_outlined,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 14),
            const Icon(Icons.check_circle, color: _green, size: 26),
            const SizedBox(width: 6),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => setState(() => _playing = !_playing),
              icon: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cover: mengambil gambar dari backend, kalau kosong/gagal pakai placeholder warna
  Widget _cover(Color color, double size, {String? url}) {
    final placeholder = Container(
      width: size,
      height: size,
      color: color.withOpacity(0.85),
      child: Icon(
        Icons.music_note,
        color: Colors.black.withOpacity(0.55),
        size: size * 0.4,
      ),
    );

    if (url == null || url.isEmpty) return placeholder;

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
