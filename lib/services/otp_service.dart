import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send email verification (current method)
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('✅ Email verification sent to: ${user.email}');
      }
    } catch (e) {
      debugPrint('❌ Error sending email verification: $e');
      rethrow;
    }
  }

  /// Check if email is verified
  Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _auth.currentUser;
        return updatedUser?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking email verification: $e');
      return false;
    }
  }

  // SMS OTP Methods (Alternative approach)

  String? _verificationId;

  /// Send SMS OTP to phone number
  Future<void> sendSMSOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          debugPrint('✅ Phone auto-verified');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.message}');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          debugPrint('✅ SMS OTP sent to: $phoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('⏱️ SMS OTP timeout');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('❌ Error sending SMS OTP: $e');
      rethrow;
    }
  }

  /// Verify SMS OTP code
  Future<bool> verifySMSOTP(String otpCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID found. Please request OTP again.');
      }

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      // Link phone credential to current user
      final user = _auth.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
        debugPrint('✅ Phone number verified and linked');
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
