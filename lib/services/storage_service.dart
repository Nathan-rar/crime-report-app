import 'package:image_picker/image_picker.dart';

import 'local_image_store.dart';

class StorageService {
  final LocalImageStore _localImages = LocalImageStore.instance;

  Future<String> uploadReportPhoto({
    required XFile file,
    required String reportId,
  }) {
    return _saveLocalImage(file: file, ownerType: 'report', ownerId: reportId);
  }

  Future<String> uploadUserPhoto({
    required XFile file,
    required String userId,
  }) {
    return _saveLocalImage(file: file, ownerType: 'user', ownerId: userId);
  }

  Future<void> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    if (_localImages.isLocalImageRef(url)) {
      await _localImages.deleteImage(url);
    }
  }

  Future<String> _saveLocalImage({
    required XFile file,
    required String ownerType,
    required String ownerId,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return _localImages.saveImage(
        ownerType: ownerType,
        ownerId: ownerId,
        fileName: file.name,
        contentType: file.mimeType ?? 'image/jpeg',
        bytes: bytes,
      );
    } catch (error) {
      throw Exception('Gagal menyimpan foto ke database lokal SQLite: $error');
    }
  }
}
