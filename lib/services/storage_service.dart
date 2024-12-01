import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({bool isGallery = true}) async {
    final XFile? image = await _picker.pickImage(
      source: isGallery ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return image;
  }

  Future<List<XFile>> pickMultiImage() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return images;
  }

  Future<String> uploadImage(String spotId, XFile image,
      {String? folder}) async {
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
    final String filePath = folder != null
        ? 'spots/$spotId/$folder/$fileName'
        : 'spots/$spotId/$fileName';

    final ref = _storage.ref().child(filePath);
    final uploadTask = ref.putFile(File(image.path));

    final snapshot = await uploadTask.whenComplete(() {});
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<List<String>> uploadMultipleImages(
    String spotId,
    List<XFile> images,
    String folder,
  ) async {
    final List<String> uploadedUrls = [];

    for (final image in images) {
      final url = await uploadImage(spotId, image, folder: folder);
      uploadedUrls.add(url);
    }

    return uploadedUrls;
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSpotImages(String spotId) async {
    try {
      final ref = _storage.ref().child('spots/$spotId');
      await _deleteFolder(ref);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _deleteFolder(Reference folderRef) async {
    try {
      final ListResult result = await folderRef.listAll();

      for (final Reference ref in result.prefixes) {
        await _deleteFolder(ref);
      }

      for (final Reference ref in result.items) {
        await ref.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}
