class ProfileData {
  final String name;
  final String username;
  final String email;
  final String bio;
  final String avatarUrl;

  const ProfileData({
    required this.name,
    required this.username,
    required this.email,
    required this.bio,
    this.avatarUrl = '',
  });

  ProfileData copyWith({
    String? name,
    String? username,
    String? email,
    String? bio,
    String? avatarUrl,
  }) {
    return ProfileData(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}