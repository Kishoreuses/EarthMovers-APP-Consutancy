import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/phone_auth_service.dart';
import '../../core/widgets/otp_verification_dialog.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/theme/page_transitions.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/custom_app_bar.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import '../customer/home_screen.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _retypePasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscureText = true;
  bool _loading = false;
  String _countryCode = "+91";

  // Phone Auth state
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initiateRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final formattedPhone = "$_countryCode${_phoneController.text.trim()}";

    try {
      // Step 1: Send trust-verification OTP to phone number before creating account
      await _phoneAuthService.sendOtp(
        phoneNumber: formattedPhone,
        forceResendingToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (mounted) {
            setState(() => _loading = false);
            _openOtpVerificationSheet(formattedPhone);
          }
        },
        onVerificationFailed: (e) {
          if (mounted) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(PhoneAuthService.getReadableErrorMessage(e)),
                backgroundColor: AppTheme.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        onVerificationCompleted: (credential) async {
          // Instant verification on physical Android devices
          await _completeRegistrationWithCredential(credential, formattedPhone);
        },
        onCodeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(PhoneAuthService.getReadableErrorMessage(e)),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _openOtpVerificationSheet(String formattedPhone) {
    OtpVerificationDialog.show(
      context: context,
      phoneNumber: formattedPhone,
      onVerify: (otp) async {
        if (_verificationId == null) {
          throw Exception("Verification session expired. Please request a new OTP.");
        }

        final credential = _phoneAuthService.createCredential(
          verificationId: _verificationId!,
          smsCode: otp,
        );

        await _completeRegistrationWithCredential(credential, formattedPhone);
      },
      onResend: () async {
        await _phoneAuthService.sendOtp(
          phoneNumber: formattedPhone,
          forceResendingToken: _resendToken,
          onCodeSent: (verificationId, resendToken) {
            _verificationId = verificationId;
            _resendToken = resendToken;
          },
          onVerificationFailed: (e) {
            throw Exception(PhoneAuthService.getReadableErrorMessage(e));
          },
          onVerificationCompleted: (_) {},
          onCodeAutoRetrievalTimeout: (id) => _verificationId = id,
        );
      },
    );
  }

  Future<void> _completeRegistrationWithCredential(
    PhoneAuthCredential credential,
    String formattedPhone,
  ) async {
    try {
      // Step 2: Create user in Firebase Auth with Email and Password
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Link phone credential if available
      try {
        await userCred.user?.linkWithCredential(credential);
      } catch (e) {
        debugPrint("Phone link notice (non-fatal): $e");
      }

      // Step 3: Store user document in Firestore with verified phone status
      await _firestore.collection("Users").doc(userCred.user!.uid).set({
        "email": _emailController.text.trim(),
        "username": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
        "phone": formattedPhone,
        "phone_verified": true,
        "role": "user",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Cache role in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', 'user');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text("Phone verified & account created!"),
              ],
            ),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Smoothly navigate straight to Home dashboard
        Navigator.pushAndRemoveUntil(
          context,
          FadeScalePageRoute(page: const Home()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Account creation error: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showOrbs: true,
      appBar: const GlassAppBar(
        title: "Create Account",
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: AppTheme.radiusXl,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Join Kadavul Earthmovers",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sign up to book machinery and track orders",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _usernameController,
                          label: "Username",
                          icon: Icons.person_outline_rounded,
                          isPassword: false,
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          isPassword: false,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildPhoneField(),
                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        _buildTextField(
                          controller: _retypePasswordController,
                          label: "Re-Type Password",
                          icon: Icons.lock_reset_rounded,
                          isPassword: true,
                        ),

                        const SizedBox(height: 12),
                        // Trust & Security Notice
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAmber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryAmber.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: AppTheme.primaryAmber,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "A 6-digit OTP code will be sent to your phone number for trust verification.",
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11.5,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        GradientButton(
                          label: "Verify Phone & Sign Up",
                          icon: Icons.sms_rounded,
                          isLoading: _loading,
                          onPressed: _initiateRegistration,
                          gradient: AppTheme.amberGradient,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.poppins(
                          color: AppTheme.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.amber),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
          filled: true,
          fillColor: const Color(0x14FFFFFF),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Please enter $label";
          if (label == "Email Address" &&
              !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value.trim())) {
            return "Enter a valid email address";
          }
          if (isPassword && value.length < 6) return "Password must be at least 6 characters";
          if (label == "Re-Type Password" && value != _passwordController.text) {
            return "Passwords do not match";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: AppTheme.surfaceLight,
                value: _countryCode,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.amber),
                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
                onChanged: (String? newValue) {
                  if (newValue != null) setState(() => _countryCode = newValue);
                },
                items: ["+91", "+1", "+44", "+61", "+81"].map((String code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(code),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                counterText: "",
                labelText: "Phone Number",
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                hintText: "98765 43210",
                hintStyle: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.amber),
                filled: true,
                fillColor: const Color(0x14FFFFFF),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Please enter phone number";
                if (value.trim().length != 10) return "Enter a valid 10-digit number";
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
