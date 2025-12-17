import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase with your project credentials
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _instance = SupabaseService._();
  }

  /// Sign out from Supabase
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      if (kDebugMode) {
        debugPrint('Supabase: Signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Sign out error: $e');
      }
      rethrow;
    }
  }

  // User Profile Methods

  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('uid', uid)
          .maybeSingle();
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Error getting user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile in database
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      await client
          .from('user_profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('uid', uid);
      if (kDebugMode) {
        debugPrint('Supabase: User profile updated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Error updating user profile: $e');
      }
      rethrow;
    }
  }

  // Storage Methods

  /// Upload file to Supabase Storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    String? contentType,
  }) async {
    try {
      await client.storage
          .from(bucket)
          .upload(
            path,
            file,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      if (kDebugMode) {
        debugPrint('Supabase: File uploaded to $publicUrl');
      }
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Error uploading file: $e');
      }
      rethrow;
    }
  }

  /// Download file from Supabase Storage
  Future<File> downloadFile({
    required String bucket,
    required String path,
    required String localPath,
  }) async {
    try {
      final bytes = await client.storage.from(bucket).download(path);
      final file = File(localPath);
      await file.writeAsBytes(bytes);
      if (kDebugMode) {
        debugPrint('Supabase: File downloaded to $localPath');
      }
      return file;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Error downloading file: $e');
      }
      rethrow;
    }
  }

  /// Delete file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage.from(bucket).remove([path]);
      if (kDebugMode) {
        debugPrint('Supabase: File deleted from $path');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Error deleting file: $e');
      }
      rethrow;
    }
  }

  /// Get public URL for a file
  String getPublicUrl({required String bucket, required String path}) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  // Current User

  /// Get current user ID from Supabase Auth
  String? get currentUserId {
    return AuthService().currentUserId;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return AuthService().isSignedIn;
  }
}
