import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../utils/validators.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  bool _uploading = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _pickAndUploadPhoto() async {
    if (kIsWeb) {
      _showInfo("L'upload de photo de profil se fait sur mobile dans ce build.");
      return;
    }
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await _storageService.uploadProfilePhoto(
        uid: _uid,
        file: File(file.path),
      );
      await _userService.updateProfile(uid: _uid, photoUrl: url);
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
      if (!mounted) return;
      _showInfo('Photo mise à jour.');
    } catch (e) {
      if (!mounted) return;
      _showError("Échec de l'upload.");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editDisplayName(UserModel user) async {
    final controller = TextEditingController(text: user.displayName);
    final formKey = GlobalKey<FormState>();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le pseudo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Pseudo'),
            validator: Validators.displayName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newName == null || newName == user.displayName) return;
    try {
      await _userService.updateProfile(uid: _uid, displayName: newName);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
      if (!mounted) return;
      _showInfo('Pseudo mis à jour.');
    } catch (_) {
      if (!mounted) return;
      _showError("Impossible de mettre à jour le pseudo.");
    }
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.signOut();
    }
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: StreamBuilder<UserModel?>(
        stream: _userService.watchUser(_uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snap.data!;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Center(
                child: Stack(
                  children: [
                    UserAvatar(
                      photoUrl: user.photoUrl,
                      displayName: user.displayName,
                      radius: 56,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _uploading ? null : _pickAndUploadPhoto,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user.email,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 32),
              _Section(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Pseudo'),
                    subtitle: Text(user.displayName),
                    trailing: const Icon(Icons.edit_outlined, size: 18),
                    onTap: () => _editDisplayName(user),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.alternate_email),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Inscrit'),
                    subtitle: Text(
                      DateFormatter.lastSeen(user.createdAt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout,
                        color: Colors.redAccent),
                    title: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: _confirmSignOut,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}
