import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/realm_database_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

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

  /// Get auth state stream
  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((data) => data.session?.user);

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Sign in with Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Trigger native Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found');
      }
      if (idToken == null) {
        throw Exception('No ID Token found');
      }

      // Sign in to Supabase with Google tokens
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

      debugPrint('✅ Google Sign-In successful: ${response.user!.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
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

      debugPrint('✅ Email Sign-In successful: ${response.user!.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Email Sign-In error: $e');
      rethrow;
    }
  }

  /// Create account with email and password
  Future<AuthResponse> createUserWithEmailAndPassword({
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
        throw Exception('Failed to create account');
      }

      // Create user profile
      await _ensureUserProfile(response.user!);

      debugPrint('✅ Account created successfully: ${response.user!.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Account creation error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent to: $email');
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Close Realm database before signing out
      await RealmDatabaseHelper().closeRealm();

      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Supabase
      await _client.auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId != null) {
        // Delete user profile (will cascade delete all user data)
        await _client.from('user_profiles').delete().eq('uid', userId);
        debugPrint('✅ Account deleted successfully');
      }
    } catch (e) {
      debugPrint('❌ Account deletion error: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final userId = currentUserId;
      if (userId != null) {
        final updates = <String, dynamic>{};
        if (displayName != null) updates['display_name'] = displayName;
        if (photoURL != null) updates['custom_avatar_url'] = photoURL;

        if (updates.isNotEmpty) {
          await _client.from('user_profiles').update(updates).eq('uid', userId);
          debugPrint('✅ Profile updated successfully');
        }
      }
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
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

      debugPrint('✅ User profile ensured for $uid');
    } catch (e) {
      debugPrint('⚠️ Error ensuring user profile: $e');
    }
  }

  /// Get user info as a map
  Map<String, dynamic>? get userInfo {
    final user = currentUser;
    if (user == null) return null;

    return {
      'uid': user.id,
      'email': user.email,
      'displayName':
          user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'],
      'photoURL':
          user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      'emailVerified': user.emailConfirmedAt != null,
      'createdAt': user.createdAt,
      'lastSignInAt': user.lastSignInAt,
      'provider': user.appMetadata['provider'],
    };
  }

  /// Handle authentication errors with user-friendly messages
  String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          if (error.message.contains('Invalid login credentials')) {
            return 'Incorrect email or password. Please try again.';
          }
          if (error.message.contains('Email not confirmed')) {
            return 'Please verify your email address before signing in.';
          }
          return 'Invalid request. Please check your input.';
        case '422':
          if (error.message.contains('already registered')) {
            return 'An account already exists with this email address.';
          }
          if (error.message.contains('Password should be')) {
            return 'The password is too weak. Please choose a stronger password.';
          }
          return 'Invalid email or password format.';
        case '429':
          return 'Too many failed attempts. Please try again later.';
        case '500':
          return 'Server error. Please try again later.';
        default:
          return error.message;
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
