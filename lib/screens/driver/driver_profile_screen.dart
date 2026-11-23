import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class DriverProfile extends StatefulWidget {
  const DriverProfile({Key? key}) : super(key: key);

  @override
  _DriverProfileState createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  User? currentUser;
  String? email;
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    email = currentUser?.email;
    _fetchDriverDetails();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchDriverDetails() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(currentUser!.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _usernameController.text = userDoc['username'] ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      if (currentUser != null) {
        await _firestore.collection('Users').doc(currentUser!.uid).update({
          'username': _usernameController.text.trim(),
        });

        if (_newPasswordController.text.trim().isNotEmpty) {
          await currentUser!.updatePassword(_newPasswordController.text.trim());
          _newPasswordController.clear();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _logout() async {
    if (currentUser != null) {
      await _firestore.collection('Users').doc(currentUser!.uid).update({
        'status': 'leave',
      });
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteManager.signin,
          (route) => false,
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text("Confirm Logout", style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          "Logging out will mark your status as 'On Leave'. Do you want to proceed?",
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: Text("Log Out", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          'Driver Profile',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.blue, width: 2),
                        boxShadow: AppTheme.glowShadow(AppTheme.blue, blur: 20),
                      ),
                      child: const CircleAvatar(
                        radius: 46,
                        backgroundColor: AppTheme.surfaceLight,
                        child: Icon(Icons.drive_eta_rounded, size: 48, color: AppTheme.blueLight),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _usernameController.text.isNotEmpty ? _usernameController.text : 'Driver',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? '',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        "LICENSED OPERATOR",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.blueLight,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Credentials GlassCard
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: AppTheme.radiusXl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile Settings",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username Input
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Driver Name',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.blue),
                        filled: true,
                        fillColor: const Color(0x14FFFFFF),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.blue, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // New Password Input
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Change Password (optional)',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.blue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0x14FFFFFF),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.blue, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GradientButton(
                      label: "Update Profile",
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      gradient: AppTheme.blueGradient,
                      onPressed: _updateProfile,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Logout GlassCard
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppTheme.radiusXl,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.red.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppTheme.red, size: 20),
                  ),
                  title: Text(
                    "Sign Out",
                    style: GoogleFonts.poppins(
                      color: AppTheme.redLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                  onTap: _confirmLogout,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
