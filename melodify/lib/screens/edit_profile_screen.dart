import 'package:flutter/material.dart';
import 'package:melodify/models/profile_data.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileData profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const green = Color(0xFF1DB954);
  static const surface = Color(0xFF242424);
  static const muted = Color(0xFFB3B3B3);

  late final TextEditingController nameController;
  late final TextEditingController usernameController;
  late final TextEditingController emailController;
  late final TextEditingController bioController;
  late final TextEditingController avatarController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.profile.name);
    usernameController = TextEditingController(text: widget.profile.username);
    emailController = TextEditingController(text: widget.profile.email);
    bioController = TextEditingController(text: widget.profile.bio);
    avatarController = TextEditingController(text: widget.profile.avatarUrl);
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    bioController.dispose();
    avatarController.dispose();
    super.dispose();
  }

  InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: muted),
      prefixIcon: Icon(icon, color: muted),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green),
      ),
    );
  }

  void saveProfile() {
    final name = nameController.text.trim();
    final username = usernameController.text.trim().replaceAll('@', '');
    final email = emailController.text.trim();

    if (name.isEmpty || username.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, username, dan email wajib diisi.')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email belum valid.')),
      );
      return;
    }

    Navigator.pop(
      context,
      widget.profile.copyWith(
        name: name,
        username: username,
        email: email,
        bio: bioController.text.trim(),
        avatarUrl: avatarController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: const Color(0xFF383838),
                      backgroundImage: url.isNotEmpty
                          ? NetworkImage(url)
                          : null,
                      child: url.isEmpty
                          ? const Icon(Icons.person, size: 55, color: muted)
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: showAvatarDialog,
                      icon: const Icon(Icons.camera_alt_outlined, color: green),
                      label: const Text(
                        'Change Photo',
                        style: TextStyle(color: green),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                decoration: decoration('Full Name', Icons.person_outline),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: usernameController,
                decoration: decoration('Username', Icons.alternate_email),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: decoration('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: decoration('Bio', Icons.edit_note),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: avatarController,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                decoration: decoration(
                  'Profile Photo URL (optional)',
                  Icons.image_outlined,
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showAvatarDialog() async {
    final controller = TextEditingController(text: avatarController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Change Profile Photo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Paste image URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save', style: TextStyle(color: green)),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && mounted) {
      avatarController.text = result;
      setState(() {});
    }
  }
}