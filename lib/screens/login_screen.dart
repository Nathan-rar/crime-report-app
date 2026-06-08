import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.initialSignUp = false, super.key});

  final bool initialSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _picker = ImagePicker();

  late bool _isSignUp;
  XFile? _photo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (photo == null || !mounted) {
      return;
    }
    setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await _authService.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          photo: _photo,
        );
      } else {
        await _authService.signInReporter(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Autentikasi gagal: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        maxWidth: 520,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 84, showLabel: true)),
                const SizedBox(height: 24),
                AppPanel(
                  icon: _isSignUp ? Icons.person_add_alt : Icons.login,
                  title: _isSignUp ? 'Buat Akun Pelapor' : 'Masuk Pelapor',
                  subtitle: _isSignUp
                      ? 'Gunakan email aktif dan foto profil untuk identitas laporan.'
                      : 'Kelola laporan kejadian dan pantau klasifikasi kasus.',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isSignUp) ...[
                          _PhotoPicker(
                            hasPhoto: _photo != null,
                            onCamera: () => _pickPhoto(ImageSource.camera),
                            onGallery: () => _pickPhoto(ImageSource.gallery),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _nameController,
                            label: 'Nama lengkap',
                            icon: Icons.badge_outlined,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!value.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          label: _isSignUp ? 'Daftar' : 'Masuk',
                          icon: _isSignUp ? Icons.person_add_alt : Icons.login,
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp
                                ? 'Sudah punya akun? Masuk'
                                : 'Belum punya akun? Daftar',
                          ),
                        ),
                        if (!_isSignUp) ...[
                          const Divider(height: 24),
                          OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminLoginScreen(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Masuk sebagai Admin'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.hasPhoto,
    required this.onCamera,
    required this.onGallery,
  });

  final bool hasPhoto;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.skyBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.silver),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: hasPhoto ? AppColors.success : AppColors.deepBlue,
            child: Icon(
              hasPhoto ? Icons.check_circle_outline : Icons.person_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? 'Foto profil dipilih' : 'Foto profil',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onCamera,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
