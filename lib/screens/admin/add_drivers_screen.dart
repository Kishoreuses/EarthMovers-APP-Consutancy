import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'drivers_screen.dart';

class AddDrivers extends StatefulWidget {
  const AddDrivers({super.key});

  @override
  State<AddDrivers> createState() => _AddDriversState();
}

class _AddDriversState extends State<AddDrivers> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> addDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final existing = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              title: Text('Email Already Exists', style: GoogleFonts.poppins(color: AppTheme.amber)),
              content: Text(
                'A driver with this email is already registered in the system.',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: AppTheme.amber)),
                ),
              ],
            ),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('Users').add({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'driver',
          'status': 'leave',
          'available': true,
          'todayJobs': 0,
          'lastJobReset': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Driver registered successfully!'),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Drivers()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add driver: $e'),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showOrbs: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Register New Driver',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: AppTheme.radiusXl,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Credentials',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create driver account for order & machinery assignment',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(_usernameController, 'Driver Full Name', Icons.person_outline_rounded),
                  _buildInputField(
                    _emailController,
                    'Email Address',
                    Icons.email_outlined,
                    inputType: TextInputType.emailAddress,
                  ),
                  _buildInputField(_passwordController, 'Password', Icons.lock_outline_rounded, isPassword: true),
                  _buildInputField(
                    _phoneController,
                    'Phone Number',
                    Icons.phone_outlined,
                    inputType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Register Driver',
                    icon: Icons.person_add_rounded,
                    isLoading: _isLoading,
                    gradient: AppTheme.amberGradient,
                    onPressed: addDriver,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: inputType,
        style: const TextStyle(color: AppTheme.textPrimary),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Password' && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.amber, size: 20),
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
      ),
    );
  }
}
