import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({Key? key}) : super(key: key);

  @override
  _AdminProfileState createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _adminData;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditingUsername = false;
  bool _isEditingPhone = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _getAdminUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _getAdminUser() async {
    _user = _auth.currentUser;
    if (_user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(_user!.uid).get();

        if (userDoc.exists && mounted) {
          setState(() {
            _adminData = userDoc.data() as Map<String, dynamic>?;
            _usernameController.text = _adminData?['username'] ?? '';
            _phoneController.text = _adminData?['phone'] ?? '';
          });
        } else {
          // Fallback query by role
          QuerySnapshot querySnapshot = await _firestore
              .collection('Users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty && mounted) {
            setState(() {
              _adminData = querySnapshot.docs.first.data() as Map<String, dynamic>?;
              _usernameController.text = _adminData?['username'] ?? '';
              _phoneController.text = _adminData?['phone'] ?? '';
            });
          }
        }
      } catch (e) {
        debugPrint("Error fetching admin data: $e");
      }
    }
  }

  Future<void> _updateAdminData() async {
    if (_user == null) return;
    setState(() => _isSaving = true);

    try {
      await _firestore.collection('Users').doc(_user!.uid).update({
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Admin Profile Updated Successfully'),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update Failed: $e'),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditingUsername = false;
        _isEditingPhone = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteManager.signin,
        (route) => false,
      );
    }
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
          'Admin Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: _adminData == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.amber))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Shield Avatar Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.amber, width: 2),
                            boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 20),
                          ),
                          child: const CircleAvatar(
                            radius: 46,
                            backgroundColor: AppTheme.surfaceLight,
                            child: Icon(Icons.shield_rounded, size: 52, color: AppTheme.amber),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _usernameController.text.isNotEmpty ? _usernameController.text : 'Administrator',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
                          ),
                          child: Text(
                            "SYSTEM ADMINISTRATOR",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.amber,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Admin Information GlassCard
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: AppTheme.radiusXl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Administrator Credentials",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Username Field
                        _buildField(
                          label: 'Username',
                          controller: _usernameController,
                          icon: Icons.person_outline_rounded,
                          isEditing: _isEditingUsername,
                          onToggleEdit: () => setState(() => _isEditingUsername = !_isEditingUsername),
                        ),
                        const SizedBox(height: 12),

                        // Phone Field
                        _buildField(
                          label: 'Contact Phone',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          isEditing: _isEditingPhone,
                          onToggleEdit: () => setState(() => _isEditingPhone = !_isEditingPhone),
                        ),

                        if (_isEditingUsername || _isEditingPhone) ...[
                          const SizedBox(height: 20),
                          GradientButton(
                            label: "Save Changes",
                            icon: Icons.save_outlined,
                            isLoading: _isSaving,
                            gradient: AppTheme.emeraldGradient,
                            onPressed: _updateAdminData,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logout Card
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
                      onTap: _logout,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    VoidCallback? onToggleEdit,
  }) {
    return TextFormField(
      controller: controller,
      enabled: isEditing,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.amber, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            isEditing ? Icons.check_circle_outline_rounded : Icons.edit_outlined,
            color: isEditing ? AppTheme.emerald : AppTheme.amber,
            size: 20,
          ),
          onPressed: onToggleEdit,
        ),
        filled: true,
        fillColor: isEditing ? const Color(0x1AFFFFFF) : const Color(0x0EFFFFFF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: isEditing ? AppTheme.amber.withOpacity(0.6) : AppTheme.glassBorder,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
        ),
      ),
    );
  }
}
