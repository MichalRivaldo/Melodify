import 'package:flutter/material.dart';

import '../models/profile_data.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color green = Color(0xFF1DB954);
  static const Color muted = Color(0xFFB3B3B3);
  static const Color background = Color(0xFF121212);

  // Data contoh untuk tampilan profil.
  // Nanti bisa dihubungkan ke AuthProvider.
  ProfileData profile = const ProfileData(
    name: 'Audi Pratiwi',
    username: 'audi',
    email: 'audi@example.com',
    bio: 'music is my safe place ♡',
  );

  final List<Map<String, Object>> playlists = [
    {
      'title': '( devotion ) ୨',
      'subtitle': '1 save',
      'icon': Icons.music_note,
      'color': const Color(0xFF9B8A80),
    },
    {
      'title': 'めてほ',
      'subtitle': '1 save',
      'icon': Icons.headphones,
      'color': const Color(0xFF777777),
    },
    {
      'title': 'always listening',
      'subtitle': '1 save',
      'icon': Icons.nightlight_round,
      'color': const Color(0xFF514B47),
    },
  ];

  Future<void> openEditProfile() async {
    final result = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
    );

    if (!mounted || result == null) return;

    setState(() {
      profile = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile berhasil diperbarui!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1ED760),
              Color(0xFF168A50),
              Color(0xFF104D35),
              Color(0xFF121212),
            ],
            stops: [0.0, 0.20, 0.42, 0.72],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // PROFILE HEADER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BACK BUTTON
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0x33292929),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.maybePop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                            tooltip: 'Back',
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // AVATAR AND FOLLOWERS
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 58,
                            backgroundColor: const Color(0xFF383838),
                            backgroundImage: profile.avatarUrl.isNotEmpty
                                ? NetworkImage(profile.avatarUrl)
                                : null,
                            child: profile.avatarUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 58,
                                    color: muted,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '257 followers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '5 following',
                                  style: TextStyle(color: muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // PROFILE NAME
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '@${profile.username}',
                        style: const TextStyle(color: muted),
                      ),

                      const SizedBox(height: 5),

                      Text(profile.email, style: const TextStyle(color: muted)),

                      if (profile.bio.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          profile.bio,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // EDIT PROFILE BUTTON
                      OutlinedButton(
                        onPressed: openEditProfile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // PLAYLIST SECTION
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Playlists',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 22),

                    ...playlists.map((playlist) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            // PLAYLIST COVER
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                color: playlist['color'] as Color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                playlist['icon'] as IconData,
                                color: Colors.white70,
                                size: 36,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // PLAYLIST INFORMATION
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    playlist['subtitle'] as String,
                                    style: const TextStyle(color: muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}