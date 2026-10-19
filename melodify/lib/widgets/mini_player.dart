import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

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

Color _colorFor(int i) => _palette[i.abs() % _palette.length];

// MiniPlayer muncul di bagian bawah layar ketika ada lagu yang diputar.
// Menggunakan PageView untuk animasi geser (swipe) antar lagu serta tombol + / check_circle ala Spotify.
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  PageController? _pageController;
  int _targetIndex = -1;
  int _lastQueueLength = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _syncPage(int currentIndex, int totalCount) {
    if (currentIndex < 0 || currentIndex >= totalCount) return;

    if (_pageController == null || _lastQueueLength != totalCount) {
      _pageController?.dispose();
      _pageController = PageController(initialPage: currentIndex);
      _targetIndex = currentIndex;
      _lastQueueLength = totalCount;
      return;
    }

    if (_targetIndex != currentIndex) {
      _targetIndex = currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pageController == null || !_pageController!.hasClients) return;
        final currentPage = _pageController!.page?.round() ?? -1;
        if (currentPage != currentIndex) {
          if ((currentPage - currentIndex).abs() == 1) {
            _pageController!.animateToPage(
              currentIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          } else {
            _pageController!.jumpToPage(currentIndex);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final currentSong = player.currentSong;

    // Jika tidak ada lagu yang diputar, sembunyikan mini player
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final songs = player.queue.isNotEmpty ? player.queue : [currentSong];
    final currentIndex = songs.indexWhere((s) => s.id == currentSong.id);
    final safeIndex = currentIndex != -1 ? currentIndex : 0;

    _syncPage(safeIndex, songs.length);

    return SizedBox(
      height: 60,
      child: PageView.builder(
        controller: _pageController,
        itemCount: songs.length,
        onPageChanged: (index) {
          if (index != _targetIndex && index >= 0 && index < songs.length) {
            _targetIndex = index;
            player.playSong(songs[index]);
          }
        },
        itemBuilder: (context, index) {
          final song = songs[index];
          final isCurrent = song.id == currentSong.id;
          return _buildMiniCard(context, player, song, index, isCurrent);
        },
      ),
    );
  }

  Widget _buildMiniCard(
    BuildContext context,
    PlayerProvider player,
    Song song,
    int index,
    bool isCurrent,
  ) {
    final songColor = _colorFor(song.id);
    final isLiked = player.isLiked(song.id);

    return GestureDetector(
      onTap: () {
        // Buka layar pemutar penuh
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFF2A2A2A), songColor, 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _cover(songColor, 40, url: song.coverUrl),
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
                    song.artistName,
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
            // Tombol icon + / check_circle ala Spotify
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final nowLiked = await player.toggleLike(song.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      nowLiked
                          ? 'Ditambahkan ke Lagu yang Disukai'
                          : 'Dihapus dari Lagu yang Disukai',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: nowLiked
                        ? const Color(0xFF1DB954)
                        : const Color(0xFF282828),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Icon(
                isLiked ? Icons.check_circle : Icons.add_circle_outline,
                color: isLiked ? _green : Colors.white70,
                size: 26,
              ),
            ),
            const SizedBox(width: 6),
            // Tombol Play / Pause
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () {
                if (!isCurrent) {
                  player.playSong(song);
                } else {
                  player.togglePlay();
                }
              },
              icon: (isCurrent && player.isLoading)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      (isCurrent && player.isPlaying)
                          ? Icons.pause
                          : Icons.play_arrow,
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
      color: color.withValues(alpha: 0.85),
      child: Icon(
        Icons.music_note,
        color: Colors.black.withValues(alpha: 0.55),
        size: size * 0.4,
      ),
    );

    if (url == null || url.isEmpty) return placeholder;

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
