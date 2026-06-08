import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/report_model.dart';
import '../services/location_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/stored_image.dart';
import 'map_picker_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({this.initialReport, this.adminMode = false, super.key});

  final ReportModel? initialReport;
  final bool adminMode;

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
  LatLng? _selectedLocation;
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
      if (report.latitude != null && report.longitude != null) {
        _selectedLocation = LatLng(report.latitude!, report.longitude!);
      }
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
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil lokasi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _pickLocationOnMap() async {
    final location = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (location == null || !mounted) {
      return;
    }

    setState(() => _selectedLocation = location);
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
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
        );
      } else {
        await _reportService.createReport(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _category,
          image: _image,
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Laporan' : 'Buat Laporan')),
      body: AppPage(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppPanel(
                icon: Icons.assignment_outlined,
                title: 'Informasi Kejadian',
                subtitle:
                    'Lengkapi data utama agar laporan mudah ditindaklanjuti.',
                child: Column(
                  children: [
                    AppTextField(
                      controller: _titleController,
                      label: 'Judul laporan',
                      icon: Icons.title,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Judul wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Deskripsi kejadian',
                      icon: Icons.description_outlined,
                      maxLines: 5,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppPanel(
                icon: Icons.photo_camera_outlined,
                title: 'Foto Bukti',
                subtitle:
                    'Ambil dari kamera atau galeri, lalu disimpan ke database lokal perangkat.',
                child: _EvidencePicker(
                  image: _image,
                  existingImageUrl: widget.initialReport?.imageUrl,
                  onCamera: () => _pickImage(ImageSource.camera),
                  onGallery: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(height: 12),
              AppPanel(
                icon: Icons.map_outlined,
                title: 'Lokasi Kejadian',
                subtitle:
                    'Pilih titik di peta OpenStreetMap atau gunakan GPS perangkat.',
                child: _LocationPicker(
                  label: _locationLabel(),
                  isLoading: _isGettingLocation,
                  onCurrentLocation: _getLocation,
                  onMapPicker: _pickLocationOnMap,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Kirim Laporan',
                icon: Icons.save_outlined,
                onPressed: _isEdit && !widget.adminMode ? null : _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _locationLabel() {
    if (_selectedLocation != null) {
      return '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}';
    }

    return 'Belum memilih lokasi';
  }
}

class _EvidencePicker extends StatelessWidget {
  const _EvidencePicker({
    required this.image,
    required this.existingImageUrl,
    required this.onCamera,
    required this.onGallery,
  });

  final XFile? image;
  final String? existingImageUrl;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final hasNewImage = image != null;
    final hasExistingImage =
        existingImageUrl != null && existingImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.skyBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.silver),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasNewImage || hasExistingImage
                      ? AppColors.success
                      : AppColors.deepBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasNewImage || hasExistingImage
                      ? Icons.check_circle_outline
                      : Icons.image_not_supported_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasNewImage
                      ? image!.name
                      : hasExistingImage
                      ? 'Foto sebelumnya tersedia'
                      : 'Belum ada foto bukti',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        if (!hasNewImage && hasExistingImage) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: StoredImage(imageRef: existingImageUrl!),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.label,
    required this.isLoading,
    required this.onCurrentLocation,
    required this.onMapPicker,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onCurrentLocation;
  final VoidCallback onMapPicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InlineInfo(icon: Icons.my_location_outlined, label: label),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: isLoading ? null : onCurrentLocation,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_outlined),
              label: const Text('Lokasi Saat Ini'),
            ),
            OutlinedButton.icon(
              onPressed: onMapPicker,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Pilih di Peta'),
            ),
          ],
        ),
      ],
    );
  }
}
