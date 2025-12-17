import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Check if email is verified
  /// Note: Supabase handles email verification via magic links sent automatically
  Future<bool> checkEmailVerification() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        // In Supabase, email is confirmed when emailConfirmedAt is not null
        return user.emailConfirmedAt != null;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking email verification: $e');
      return false;
    }
  }

  /// Resend verification email
  /// Note: Supabase sends verification email automatically on signup
  /// This method can be used to resend if needed
  Future<void> resendVerificationEmail(String email) async {
    try {
      // Supabase OTP resend API
      await _client.auth.resend(type: OtpType.signup, email: email);
      debugPrint('✅ Verification email resent to: $email');
    } catch (e) {
      debugPrint('❌ Error resending verification email: $e');
      rethrow;
    }
  }

  // SMS OTP Methods for future implementation
  // Supabase supports phone OTP via the auth.signInWithOtp method

  /// Send SMS OTP to phone number (Future implementation with Supabase)
  Future<void> sendSMSOTP(String phoneNumber) async {
    try {
      await _client.auth.signInWithOtp(phone: phoneNumber);
      debugPrint('✅ SMS OTP sent to: $phoneNumber');
    } catch (e) {
      debugPrint('❌ Error sending SMS OTP: $e');
      rethrow;
    }
  }

  /// Verify SMS OTP code (Future implementation with Supabase)
  Future<bool> verifySMSOTP(String phoneNumber, String otpCode) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: otpCode,
        type: OtpType.sms,
      );

      if (response.user != null) {
        debugPrint('✅ Phone number verified');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error verifying SMS OTP: $e');
      rethrow;
    }
  }
}

/// Verification method enum
enum VerificationMethod { email, sms }
