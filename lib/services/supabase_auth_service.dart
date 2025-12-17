import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/realm_database_helper.dart';

/// Supabase Authentication Service
/// Handles user authentication via Google OAuth and email/password
class SupabaseAuthService {
  static SupabaseAuthService? _instance;
  static SupabaseAuthService get instance =>
      _instance ??= SupabaseAuthService._();

  SupabaseAuthService._();

  SupabaseClient get _client => Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Required for Supabase authentication - gets web client ID from .env
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Check if user is signed in
  bool get isSignedIn => _client.auth.currentUser != null;

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Get Google Auth tokens
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found');
      }
      if (idToken == null) {
        throw Exception('No ID Token found');
      }

      // Sign in to Supabase with Google
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Create or update user profile
      await _ensureUserProfile(response.user!);

      if (kDebugMode) {
        debugPrint('Supabase: Signed in with Google: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Google sign in error: $e');
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in');
      }

      if (kDebugMode) {
        debugPrint('Supabase: Signed in with email: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Email sign in error: $e');
      }
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {if (displayName != null) 'display_name': displayName},
      );

      if (response.user == null) {
        throw Exception('Failed to sign up');
      }

      // Create user profile
      await _ensureUserProfile(response.user!);

      if (kDebugMode) {
        debugPrint('Supabase: Signed up with email: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Email sign up error: $e');
      }
      rethrow;
    }
  }

  /// Create or update user profile in database
  Future<void> _ensureUserProfile(User user) async {
    try {
      final uid = user.id;

      // Check if profile exists
      final existing = await _client
          .from('user_profiles')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      final profileData = {
        'uid': uid,
        'email': user.email ?? '',
        'display_name':
            user.userMetadata?['display_name'] ??
            user.userMetadata?['full_name'] ??
            user.email?.split('@').first,
        'photo_url':
            user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
        'provider': user.appMetadata['provider'] ?? 'email',
        'is_email_verified': user.emailConfirmedAt != null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing == null) {
        // Create new profile
        await _client.from('user_profiles').insert({
          ...profileData,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing profile
        await _client.from('user_profiles').update(profileData).eq('uid', uid);
      }

      if (kDebugMode) {
        debugPrint('Supabase: User profile ensured for $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Error ensuring user profile: $e');
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Close Realm database before signing out
      await RealmDatabaseHelper().closeRealm();

      await _googleSignIn.signOut();
      await _client.auth.signOut();
      if (kDebugMode) {
        debugPrint('Supabase: Signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Sign out error: $e');
      }
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Delete user profile (will cascade delete all user data)
      await _client.from('user_profiles').delete().eq('uid', userId);

      // Delete auth user
      await _client.auth.admin.deleteUser(userId);

      if (kDebugMode) {
        debugPrint('Supabase: Account deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Delete account error: $e');
      }
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('uid', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Get user profile error: $e');
      }
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? customAvatarUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (customAvatarUrl != null)
        updates['custom_avatar_url'] = customAvatarUrl;

      if (updates.isEmpty) return;

      await _client.from('user_profiles').update(updates).eq('uid', userId);

      if (kDebugMode) {
        debugPrint('Supabase: User profile updated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase: Update user profile error: $e');
      }
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
