import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload user avatar image to Firebase Storage
  Future<String> uploadAvatarImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a unique file name
      final fileName =
          'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create reference to Firebase Storage
      final Reference ref = _storage
          .ref()
          .child('user_avatars')
          .child(fileName);

      // Upload the file
      debugPrint('🔄 Uploading avatar image...');
      final UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Avatar uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      rethrow;
    }
  }

  /// Delete old avatar image from Firebase Storage (optional cleanup)
  Future<void> deleteAvatarImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('firebase')) {
        return; // Not a Firebase Storage URL
      }

      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Old avatar deleted successfully');
    } catch (e) {
      debugPrint('⚠️ Error deleting old avatar: $e');
      // Don't throw - this is cleanup, not critical
    }
  }
}
