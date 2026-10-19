import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../services/song_service.dart';
import 'playlist_detail_screen.dart';
import 'liked_songs_screen.dart';

// Halaman Library — menampilkan Lagu yang Disukai (Pinned) & Playlist milik user
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Playlist> _playlists = [];
  int _likedSongsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        PlaylistService.getMyPlaylists(),
        SongService.getLikedSongs(),
      ]);

      if (mounted) {
        setState(() {
          _playlists = results[0] as List<Playlist>;
          _likedSongsCount = (results[1] as List).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Dialog untuk membuat playlist baru
  Future<void> _showCreatePlaylistDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Playlist baru',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Nama playlist',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1DB954))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Deskripsi (opsional)',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1DB954))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final playlist = await PlaylistService.createPlaylist(
                name,
                descController.text.trim(),
              );

              if (playlist != null && mounted) {
                Navigator.pop(dialogCtx);
                setState(() => _playlists.insert(0, playlist));
              }
            },
            child: const Text(
              'Buat',
              style: TextStyle(
                  color: Color(0xFF1DB954), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Library',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: _showCreatePlaylistDialog,
                      icon: const Icon(Icons.add, color: Colors.white, size: 28),
                      tooltip: 'Buat playlist',
                    ),
                  ],
                ),
              ),
            ),

            // Konten Library
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF1DB954)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF1DB954),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          // 1. Pinned Playlist: Lagu yang Disukai (selalu tampil paling atas)
                          _buildLikedSongsTile(),

                          const Divider(
                            color: Color(0xFF282828),
                            height: 16,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),

                          // 2. Daftar Playlist Pribadi Pengguna
                          if (_playlists.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 32, horizontal: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.queue_music,
                                        color: Colors.grey, size: 40),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Buat playlist pertamamu',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Mudah, kami akan membantumu',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _showCreatePlaylistDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 8),
                                      ),
                                      child: const Text(
                                        'Buat playlist',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._playlists.map((pl) => _buildPlaylistTile(pl)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Tile Pinned "Lagu yang Disukai"
  Widget _buildLikedSongsTile() {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF450af5), Color(0xFF8e8ee5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF450af5).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 28),
      ),
      title: const Text(
        'Lagu yang Disukai',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.push_pin, color: Color(0xFF1DB954), size: 13),
          const SizedBox(width: 4),
          Text(
            'Playlist • $_likedSongsCount lagu',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
        );
        _loadData();
      },
    );
  }

  // Widget Tile Playlist Biasa
  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.queue_music, color: Color(0xFF1DB954)),
      ),
      title: Text(
        playlist.name,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Playlist',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
        _loadData();
      },
      trailing: PopupMenuButton<String>(
        color: const Color(0xFF282828),
        onSelected: (value) async {
          if (value == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF282828),
                title: const Text('Hapus playlist?',
                    style: TextStyle(color: Colors.white)),
                content: Text(
                  'Playlist "${playlist.name}" akan dihapus permanen.',
                  style: const TextStyle(color: Colors.grey),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child:
                        const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child:
                        const Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              final ok = await PlaylistService.deletePlaylist(playlist.id);
              if (ok && mounted) {
                setState(() => _playlists.remove(playlist));
              }
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'delete',
            child:
                Text('Hapus playlist', style: TextStyle(color: Colors.white)),
          ),
        ],
        icon: const Icon(Icons.more_vert, color: Colors.grey),
      ),
    );
  }
}
