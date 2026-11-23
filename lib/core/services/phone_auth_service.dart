import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service managing Phone Number authentication and OTP verification flows.
class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Requests Firebase Auth to send a 6-digit SMS OTP to the provided [phoneNumber].
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException exception) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint("PhoneAuth: Auto-verification completed for $phoneNumber");
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("PhoneAuth: Verification failed: ${e.code} - ${e.message}");
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("PhoneAuth: Code sent to $phoneNumber. VerificationId: $verificationId");
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("PhoneAuth: Auto retrieval timeout for $verificationId");
          onCodeAutoRetrievalTimeout(verificationId);
        },
        forceResendingToken: forceResendingToken,
      );
    } catch (e) {
      debugPrint("PhoneAuth: Unexpected error during verifyPhoneNumber: $e");
      rethrow;
    }
  }

  /// Creates a [PhoneAuthCredential] from [verificationId] and [smsCode].
  PhoneAuthCredential createCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Signs into Firebase using the given [PhoneAuthCredential].
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  /// Verifies the OTP and signs in directly, returning the [UserCredential].
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = createCredential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await signInWithCredential(credential);
  }

  /// Human-readable error message mapping for common Firebase Phone Auth errors.
  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'The entered phone number is invalid. Please check the digits.';
        case 'invalid-verification-code':
          return 'Invalid OTP code. Please check the 6-digit code and try again.';
        case 'session-expired':
          return 'OTP has expired. Please request a new code.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a while before requesting again.';
        case 'quota-exceeded':
          return 'SMS quota exceeded for today. Please try again later or use test credentials.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'billing-not-enabled':
        case 'app-not-authorized':
          return 'Phone authentication setup is incomplete in Firebase Console.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error.toString();
  }
}
