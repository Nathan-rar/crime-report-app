import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_model.dart';
import '../services/location_service.dart';
import '../services/report_service.dart';
import '../widgets/custom_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({this.initialReport, super.key});

  final ReportModel? initialReport;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reportService = ReportService();
  final _locationService = LocationService();
  final _picker = ImagePicker();
  final _categories = <String>[
    'Pencurian',
    'Kekerasan',
    'Penipuan',
    'Vandalisme',
    'Lalu Lintas',
    'Lainnya',
  ];

  String _category = 'Pencurian';
  XFile? _image;
  Position? _position;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  bool get _isEdit => widget.initialReport != null;

  @override
  void initState() {
    super.initState();
    final report = widget.initialReport;
    if (report != null) {
      _titleController.text = report.title;
      _descriptionController.text = report.description;
      if (!_categories.contains(report.category)) {
        _categories.add(report.category);
      }
      _category = report.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image == null || !mounted) {
      return;
    }
    setState(() => _image = image);
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) {
        return;
      }
      setState(() => _position = position);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEdit) {
        await _reportService.updateReport(
          reportId: widget.initialReport!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          category: _category,
          image: _image,
          position: _position,
        );
      } else {
        await _reportService.createReport(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _category,
          image: _image,
          position: _position,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan laporan: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingLocation = widget.initialReport?.latitude != null &&
        widget.initialReport?.longitude != null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Laporan' : 'Buat Laporan')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Judul laporan',
                icon: Icons.title,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                label: 'Deskripsi kejadian',
                icon: Icons.description_outlined,
                maxLines: 5,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Foto bukti', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_image != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined),
                  title: Text(_image!.name),
                  subtitle: const Text('Foto baru siap diunggah'),
                )
              else if (widget.initialReport?.imageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    widget.initialReport!.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.image_not_supported_outlined),
                  title: Text('Belum ada foto'),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Lokasi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(_locationLabel(existingLocation)),
                subtitle: const Text('Latitude dan longitude disimpan bersama laporan'),
              ),
              OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _getLocation,
                icon: _isGettingLocation
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: const Text('Ambil Lokasi Saat Ini'),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Kirim Laporan',
                icon: Icons.save_outlined,
                onPressed: _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _locationLabel(bool existingLocation) {
    if (_position != null) {
      return '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}';
    }

    if (existingLocation) {
      final report = widget.initialReport!;
      return '${report.latitude!.toStringAsFixed(6)}, ${report.longitude!.toStringAsFixed(6)}';
    }

    return 'Belum mengambil lokasi';
  }
}
