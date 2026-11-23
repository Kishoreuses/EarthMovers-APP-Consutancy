import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/phone_auth_service.dart';
import '../../core/widgets/otp_verification_dialog.dart';
import '../admin/admin_home_screen.dart';
import '../driver/driver_home_screen.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/theme/page_transitions.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import '../customer/home_screen.dart';
import 'signup_screen.dart';

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PhoneAuthService _phoneAuthService = PhoneAuthService();

  // Login Mode: 0 = Email/Password, 1 = Phone OTP
  int _selectedTab = 0;
  bool _obscureText = true;
  bool _isLoading = false;
  String _countryCode = "+91";

  // Phone Auth state
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<String?> _getEmailFromUsername(String username) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('Users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first['email'];
      }
    } catch (e) {
      debugPrint("Error fetching email: $e");
    }
    return null;
  }

  Future<void> _routeToDestination(String uid, [String? fallbackRole]) async {
    final prefs = await SharedPreferences.getInstance();

    DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(uid).get();

    String role = fallbackRole ?? 'user';
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>?;
      role = data?['role'] ?? 'user';
    }

    await prefs.setString('userRole', role);

    if (!mounted) return;

    Widget destination;
    if (role == "admin") {
      destination = const AdminHome();
    } else if (role == "driver") {
      destination = const DriverHome();
    } else {
      destination = const Home();
    }

    Navigator.of(context).pushReplacement(
      FadeScalePageRoute(page: destination),
    );
  }

  void _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String input = _usernameController.text.trim();
    String? email = input.contains('@') ? input : await _getEmailFromUsername(input);

    if (email != null) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );

        await _routeToDestination(userCredential.user!.uid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Failed: ${e.toString()}'),
              backgroundColor: AppTheme.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not found. Please check your username or email.'),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _sendPhoneOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final formattedPhone = "$_countryCode${_phoneController.text.trim()}";

    try {
      await _phoneAuthService.sendOtp(
        phoneNumber: formattedPhone,
        forceResendingToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (mounted) {
            setState(() => _isLoading = false);
            _openOtpDialog(formattedPhone);
          }
        },
        onVerificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
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
          // Instant auto-verification on Android
          try {
            final userCred = await _phoneAuthService.signInWithCredential(credential);
            await _handleSuccessfulPhoneLogin(userCred.user!, formattedPhone);
          } catch (e) {
            debugPrint("Auto verification sign in error: $e");
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.amber),
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
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(
              'Send Reset Link',
              style: GoogleFonts.poppins(
                color: AppTheme.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to ${emailController.text.trim()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reset email: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _openOtpDialog(String formattedPhone) {
    OtpVerificationDialog.show(
      context: context,
      phoneNumber: formattedPhone,
      onVerify: (otp) async {
        if (_verificationId == null) {
          throw Exception("Verification session expired. Please resend OTP.");
        }

        final userCred = await _phoneAuthService.verifyOtpAndSignIn(
          verificationId: _verificationId!,
          smsCode: otp,
        );

        await _handleSuccessfulPhoneLogin(userCred.user!, formattedPhone);
      },
      onResend: () async {
        final completer = Completer<void>();
        await _phoneAuthService.sendOtp(
          phoneNumber: formattedPhone,
          forceResendingToken: _resendToken,
          onCodeSent: (verificationId, resendToken) {
            _verificationId = verificationId;
            _resendToken = resendToken;
            if (!completer.isCompleted) completer.complete();
          },
          onVerificationFailed: (e) {
            if (!completer.isCompleted) {
              completer.completeError(
                Exception(PhoneAuthService.getReadableErrorMessage(e)),
              );
            }
          },
          onVerificationCompleted: (_) {},
          onCodeAutoRetrievalTimeout: (id) => _verificationId = id,
        );
        await completer.future;
      },
    );
  }

  Future<void> _handleSuccessfulPhoneLogin(User user, String formattedPhone) async {
    // Check if user document already exists, if not create a default entry
    final docRef = _firestore.collection('Users').doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        'phone': formattedPhone,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'phone_verified': true,
      }, SetOptions(merge: true));
    }

    await _routeToDestination(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showOrbs: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Logo & Branding
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 24),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('images/l2.jpg'),
                    radius: 46,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'KADAVUL EARTHMOVERS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Timmana',
                    fontSize: 26,
                    color: AppTheme.amber,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: AppTheme.amber.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Sign in to manage machinery & orders',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                // Glass Form Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: AppTheme.radiusXl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTab == 0
                            ? 'Enter your credentials to continue'
                            : 'Enter your phone number for instant OTP verification',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dual Login Mode Selector Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                index: 0,
                                label: "Password",
                                icon: Icons.lock_outline_rounded,
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                index: 1,
                                label: "Phone OTP",
                                icon: Icons.phone_android_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Tab 0: Password Flow
                      if (_selectedTab == 0) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Username/Email Field
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Username or Email',
                                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.amber),
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
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Please enter your username or email'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscureText,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.amber),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppTheme.textMuted,
                                    ),
                                    onPressed: () => setState(() => _obscureText = !_obscureText),
                                  ),
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
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Please enter your password'
                                        : null,
                              ),
                              const SizedBox(height: 24),

                              // Sign In Button
                              GradientButton(
                                label: 'Sign In',
                                icon: Icons.login_rounded,
                                isLoading: _isLoading,
                                onPressed: _loginWithPassword,
                                gradient: AppTheme.amberGradient,
                              ),
                              const SizedBox(height: 16),

                              // Forgot Password Link
                              GestureDetector(
                                onTap: _forgotPassword,
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.amber,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Tab 1: Phone OTP Flow
                        Form(
                          key: _phoneFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Mobile Number",
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country Code Box
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: const Color(0x14FFFFFF),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      border: Border.all(color: AppTheme.glassBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text("🇮🇳", style: TextStyle(fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _countryCode,
                                          style: GoogleFonts.inter(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Phone Number Input
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: "",
                                        hintText: '98765 43210',
                                        hintStyle: TextStyle(
                                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                                          letterSpacing: 0,
                                        ),
                                        prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.amber, size: 20),
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
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter mobile number';
                                        }
                                        if (value.trim().length != 10) {
                                          return 'Enter a valid 10-digit number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.security_rounded, size: 14, color: AppTheme.emerald),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Firebase Trust Verification • Instant 6-digit SMS OTP",
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Send OTP Button
                              GradientButton(
                                label: 'Send Verification OTP',
                                icon: Icons.sms_rounded,
                                isLoading: _isLoading,
                                onPressed: _sendPhoneOtp,
                                gradient: AppTheme.amberGradient,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        SlidePageRoute(page: const SignUp()),
                      ),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          color: AppTheme.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTab != index) {
          setState(() {
            _selectedTab = index;
            _isLoading = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
          gradient: isSelected ? AppTheme.amberGradient : null,
          color: isSelected ? null : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.amber.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.bgDark : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? AppTheme.bgDark : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
