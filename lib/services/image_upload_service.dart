import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload user avatar image to Supabase Storage
  Future<String> uploadAvatarImage(File imageFile) async {
    try {
      final userId = AuthService().currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a unique file name
      final fileName =
          'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase Storage
      debugPrint('🔄 Uploading avatar image...');
      await _client.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Get public URL
      final String publicUrl = _client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      debugPrint('✅ Avatar uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      rethrow;
    }
  }

  /// Delete old avatar image from Supabase Storage (optional cleanup)
  Future<void> deleteAvatarImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('supabase')) {
        return; // Not a Supabase Storage URL
      }

      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) return;

      // Get filename from URL (last segment)
      final fileName = pathSegments.last;

      await _client.storage.from('avatars').remove([fileName]);
      debugPrint('✅ Old avatar deleted successfully');
    } catch (e) {
      debugPrint('⚠️ Error deleting old avatar: $e');
      // Don't throw - this is cleanup, not critical
    }
  }
}
