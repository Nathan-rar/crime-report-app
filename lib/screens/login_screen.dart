import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../widgets/custom_button.dart';

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
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentikasi gagal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSignUp ? 'Buat Akun' : 'Masuk',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Daftarkan akun pelapor dan foto profil.'
                          : 'Masuk untuk membuat dan memantau laporan.',
                    ),
                    const SizedBox(height: 24),
                    if (_isSignUp) ...[
                      Center(
                        child: CircleAvatar(
                          radius: 42,
                          child: Icon(
                            _photo == null ? Icons.person_add_alt_1 : Icons.check_circle_outline,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickPhoto(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Kamera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Galeri'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nama',
                        icon: Icons.badge_outlined,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    CustomTextField(
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
                    CustomTextField(
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
                    const SizedBox(height: 20),
                    CustomButton(
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
