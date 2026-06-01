import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadReportPhoto({
    required XFile file,
    required String reportId,
  }) async {
    return _uploadFile(
      file: file,
      path: 'reports/$reportId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String> uploadUserPhoto({
    required XFile file,
    required String userId,
  }) async {
    return _uploadFile(
      file: file,
      path: 'users/$userId/profile.jpg',
    );
  }

  Future<void> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    await _storage.refFromURL(url).delete();
  }

  Future<String> _uploadFile({
    required XFile file,
    required String path,
  }) async {
    final ref = _storage.ref(path);
    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(contentType: file.mimeType ?? 'image/jpeg');
    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }
}
