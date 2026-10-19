import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

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

// Halaman Player — tampilan full-screen saat memutar lagu
// Mirip dengan Now Playing screen Spotify
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text('Tidak ada lagu yang diputar',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Hitung progress slider (0.0 - 1.0)
    final progress = player.duration.inSeconds > 0
        ? player.position.inSeconds / player.duration.inSeconds
        : 0.0;

    final songColor = _colorFor(song.id);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(songColor, const Color(0xFF121212), 0.25)!,
              Color.lerp(songColor, const Color(0xFF121212), 0.65)!,
              const Color(0xFF121212),
              const Color(0xFF121212),
            ],
            stops: const [0.0, 0.40, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

              // Header bar (chevron + menu)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      const Text(
                        'SEDANG DIPUTAR',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        song.albumTitle ?? 'Single',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showQueueBottomSheet(context, player),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Album Art — cover lagu besar (geser kiri/kanan untuk next/prev)
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -150) {
                      // Geser ke kiri → lagu berikutnya
                      player.next();
                    } else if (details.primaryVelocity! > 150) {
                      // Geser ke kanan → lagu sebelumnya
                      player.previous();
                    }
                  }
                },
                child: Hero(
                  tag: 'song-cover-${song.id}',
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: song.coverUrl != null
                          ? Image.network(
                              song.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: songColor.withValues(alpha: 0.5),
                                child: const Icon(Icons.music_note,
                                    color: Colors.white, size: 80),
                              ),
                            )
                          : Container(
                              color: songColor.withValues(alpha: 0.5),
                              child: const Icon(Icons.music_note,
                                  color: Colors.white, size: 80),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Info lagu + like button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artistName,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      player.isLiked(song.id) ? Icons.check_circle : Icons.add_circle_outline,
                      color: player.isLiked(song.id) ? const Color(0xFF1DB954) : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () async {
                      final liked = await player.toggleLike(song.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(liked ? 'Ditambahkan ke Lagu yang Disukai' : 'Dihapus dari Lagu yang Disukai'),
                            backgroundColor: liked ? const Color(0xFF1DB954) : const Color(0xFF282828),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: const Color(0xFF1DB954),
                      inactiveTrackColor: Colors.grey[700],
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF1DB954).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final newPosition = Duration(
                          seconds: (value * player.duration.inSeconds).round(),
                        );
                        player.seekTo(newPosition);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(player.position),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(player.duration),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Kontrol: Previous, Play/Pause, Next
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle (Acak)
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: player.isShuffle ? const Color(0xFF1DB954) : Colors.grey,
                      size: 24,
                    ),
                    onPressed: () => player.toggleShuffle(),
                  ),

                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 44),
                    onPressed: () => player.previous(),
                  ),

                  // Play / Pause — tombol utama
                  GestureDetector(
                    onTap: () => player.togglePlay(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: player.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : Icon(
                              player.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                              size: 40,
                            ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: Colors.white, size: 44),
                    onPressed: () => player.next(),
                  ),

                  // Repeat (Ulang)
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: player.isRepeat ? const Color(0xFF1DB954) : Colors.grey,
                      size: 24,
                    ),
                    onPressed: () => player.toggleRepeat(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Volume kontrol aktif
              Row(
                children: [
                  const Icon(Icons.volume_mute, color: Colors.grey, size: 20),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: const Color(0xFF1DB954),
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: player.volume,
                        onChanged: (val) => player.setVolume(val),
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // Format Duration → mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Bottom sheet untuk lihat & geser antrian lagu dengan animasi mulus
  void _showQueueBottomSheet(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return Consumer<PlayerProvider>(
          builder: (context, p, _) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Indikator garis drag modal
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Antrean Lagu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tahan & geser untuk atur urutan • Geser kiri untuk hapus',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.pop(bottomSheetCtx),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF2E2E2E), height: 20),
                  Expanded(
                    child: p.queue.isEmpty
                        ? const Center(
                            child: Text(
                              'Antrean kosong',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: ReorderableListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              itemCount: p.queue.length,
                              onReorder: (oldIndex, newIndex) {
                                p.reorderQueue(oldIndex, newIndex);
                              },
                              proxyDecorator: (child, index, animation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (ctx, childWidget) {
                                    final animValue = Curves.easeInOut
                                        .transform(animation.value);
                                    final elevation =
                                        (animValue * 6).toDouble();
                                    return Material(
                                      color: const Color(0xFF2C2C2C),
                                      elevation: elevation,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: childWidget,
                                    );
                                  },
                                  child: child,
                                );
                              },
                              itemBuilder: (ctx, index) {
                                final qSong = p.queue[index];
                                final isCurrentSong =
                                    p.currentSong?.id == qSong.id;

                                return Dismissible(
                                  key: ValueKey(
                                      'queue-song-${qSong.id}-$index'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding:
                                        const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red[900],
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) {
                                    p.removeFromQueue(index);
                                  },
                                  child: Container(
                                    key: ValueKey('song-item-${qSong.id}'),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCurrentSong
                                          ? const Color(0xFF1DB954)
                                              .withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 2),
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: qSong.coverUrl != null
                                            ? Image.network(
                                                qSong.coverUrl!,
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
                                                        Container(
                                                  width: 44,
                                                  height: 44,
                                                  color: const Color(
                                                      0xFF333333),
                                                  child: const Icon(
                                                      Icons.music_note,
                                                      color: Colors.grey,
                                                      size: 20),
                                                ),
                                              )
                                            : Container(
                                                width: 44,
                                                height: 44,
                                                color: const Color(
                                                    0xFF333333),
                                                child: const Icon(
                                                    Icons.music_note,
                                                    color: Colors.grey,
                                                    size: 20),
                                              ),
                                      ),
                                      title: Text(
                                        qSong.title,
                                        style: TextStyle(
                                          color: isCurrentSong
                                              ? const Color(0xFF1DB954)
                                              : Colors.white,
                                          fontWeight: isCurrentSong
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        qSong.artistName,
                                        style: TextStyle(
                                          color: isCurrentSong
                                              ? const Color(0xFF1DB954)
                                                  .withValues(alpha: 0.8)
                                              : Colors.grey,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isCurrentSong)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  right: 12),
                                              child: Icon(Icons.equalizer,
                                                  color: Color(0xFF1DB954),
                                                  size: 20),
                                            ),
                                          // Drag handle icon khas Spotify
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: const Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                  Icons.drag_handle,
                                                  color: Colors.grey,
                                                  size: 22),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        p.playSong(qSong);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
