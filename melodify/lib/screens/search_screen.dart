import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

// Halaman Search — mirip Spotify search (redesign)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Song> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // ====== LOGIC (tidak diubah) ======
  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final songs = await SongService.searchSongs(keyword.trim());

    if (mounted) {
      setState(() {
        _results = songs;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  // ====== END LOGIC ======

  // Data kategori (simulasi)
  static const _topCategories = [
    _Cat('Musik', Color(0xFFE91E8C), Icons.music_note),
    _Cat('Podcast', Color(0xFF006450), Icons.mic),
    _Cat('Acara Live', Color(0xFF8400E7), Icons.nightlife),
    _Cat('K-Pop ON!', Color(0xFF1E3264), Icons.star),
    _Cat('Untuk Kamu', Color(0xFF8D67AB), Icons.person),
  ];

  static const _discover = [
    _Cat('#fomo', Color(0xFF2A2F3A), Icons.videocam),
    _Cat('#dangdut jawa', Color(0xFF4A3B2A), Icons.music_note),
    _Cat('#metal indo', Color(0xFF1A1A1A), Icons.bolt),
  ];

  static const _browseAll = [
    _Cat('Segera Rilis', Color(0xFF056952), Icons.schedule),
    _Cat('Rilis Baru', Color(0xFF608108), Icons.fiber_new),
    _Cat('Pop', Color(0xFF477D95), Icons.album),
    _Cat('Indie', Color(0xFF8C1932), Icons.headphones),
    _Cat('Musik Indo', Color(0xFFE61E32), Icons.flag),
    _Cat('K-pop', Color(0xFFE8115B), Icons.star),
    _Cat('Hip-Hop', Color(0xFFBC5900), Icons.mic_external_on),
    _Cat('Rock', Color(0xFFE13300), Icons.electric_bolt),
    _Cat('Jazz', Color(0xFF1E3264), Icons.piano),
    _Cat('Electronic', Color(0xFF0D73EC), Icons.graphic_eq),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // Header: avatar + judul "Cari" + ikon kamera
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFB388EB),
            child: Text(
              'W',
              style: TextStyle(
                color: Color(0xFF3B1F6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cari',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // Search bar putih
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {}); // update ikon clear
          _search(value);
        },
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Apa yang ingin kamu dengarkan?',
          hintStyle: const TextStyle(
            color: Color(0xFF4D4D4D),
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 28),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black54),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // Pilih tampilan: loading / kosong / kategori / hasil
  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.grey, size: 60),
            SizedBox(height: 16),
            Text(
              'Tidak ada hasil ditemukan',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) return _buildBrowse();

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final song = _results[index];
        return SongTile(
          song: song,
          onTap: () {
            context.read<PlayerProvider>().playSong(song, songList: _results);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            );
          },
        );
      },
    );
  }

  // Tampilan awal: kategori atas, "Temukan sesuatu yang lain", "Jelajahi semua"
  Widget _buildBrowse() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        _categoryGrid(_topCategories, 2.0),
        const SizedBox(height: 20),
        const Text(
          'Temukan sesuatu yang lain',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _discover.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _discoverCard(_discover[i]),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Jelajahi semua',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _categoryGrid(_browseAll, 1.4),
      ],
    );
  }

  Widget _categoryGrid(List<_Cat> items, double ratio) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: ratio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, i) => _categoryCard(items[i]),
    );
  }

  // Kartu kategori: teks kiri atas, "cover" miring di kanan bawah
  Widget _categoryCard(_Cat cat) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: cat.color,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 10,
              right: 36,
              child: Text(
                cat.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            Positioned(
              right: -12,
              bottom: -8,
              child: Transform.rotate(
                angle: 0.45,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.black.withOpacity(0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(-2, 3),
                      ),
                    ],
                  ),
                  child: Icon(cat.icon,
                      color: Colors.white.withOpacity(0.9), size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kartu tinggi untuk "Temukan sesuatu yang lain"
  Widget _discoverCard(_Cat cat) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cat.color.withOpacity(0.6), Colors.black],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(cat.icon,
                  color: Colors.white.withOpacity(0.25), size: 64),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Icon(Icons.play_circle_outline,
                  color: Colors.white.withOpacity(0.8), size: 22),
            ),
            Positioned(
              left: 10,
              bottom: 12,
              child: Text(
                cat.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model kecil untuk data kategori
class _Cat {
  final String name;
  final Color color;
  final IconData icon;
  const _Cat(this.name, this.color, this.icon);
}