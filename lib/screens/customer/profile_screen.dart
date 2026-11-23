import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

// ─── Shimmer helper ───────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const _ShimmerBox({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.isCircle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                math.max(0, _anim.value - 0.3),
                _anim.value.clamp(0.0, 1.0),
                math.min(1, _anim.value + 0.3),
              ],
              colors: const [
                Color(0x0FFFFFFF),
                Color(0x2AFFFFFF),
                Color(0x0FFFFFFF),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Profile Screen ───────────────────────────────────────────────────────────
class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditingUsername = false;
  bool _isEditingPhone = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  // Change password controllers
  final _pwFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPwController = TextEditingController();
  final TextEditingController _newPwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPw = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _getCurrentUser() async {
    _user = _auth.currentUser;
    if (_user != null) {
      try {
        final userDoc =
            await _firestore.collection('Users').doc(_user!.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
            _usernameController.text = _userData?['username'] ?? '';
            _emailController.text =
                _userData?['email'] ?? (_user!.email ?? '');
            _phoneController.text = _userData?['phone'] ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    if (_user == null) return;
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('Users').doc(_user!.uid).update({
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (mounted) {
        _showSnackbar('Profile Updated Successfully', AppTheme.emerald);
        setState(() {
          _isEditingUsername = false;
          _isEditingPhone = false;
        });
      }
    } catch (e) {
      if (mounted) _showSnackbar('Update Failed: $e', AppTheme.red);
    }
    if (mounted) setState(() => _isSaving = false);
  }

  // ─── Profile Photo ─────────────────────────────────────────────────────────

  void _showPhotoBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
        side: BorderSide(color: AppTheme.glassBorder),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Update Profile Photo',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.amber.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppTheme.amber, size: 20),
                ),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              const Divider(color: AppTheme.glassBorder, height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.blue.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.blue, size: 20),
                ),
                title: Text('Take a Photo',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null || _user == null) return;

      setState(() => _isUploadingPhoto = true);

      final file = File(picked.path);
      final ref = _storage.ref().child('profile_photos/${_user!.uid}.jpg');
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('Users').doc(_user!.uid).update({
        'profilePhotoUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _userData = {
            ...?_userData,
            'profilePhotoUrl': downloadUrl,
          };
          _isUploadingPhoto = false;
        });
        _showSnackbar('Profile photo updated!', AppTheme.emerald);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showSnackbar('Failed to upload photo: $e', AppTheme.red);
      }
    }
  }

  // ─── Change Password ────────────────────────────────────────────────────────

  void _showChangePasswordDialog() {
    _currentPwController.clear();
    _newPwController.clear();
    _confirmPwController.clear();
    _obscureCurrent = true;
    _obscureNew = true;
    _obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: const BorderSide(color: AppTheme.glassBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: AppTheme.amber, size: 22),
              const SizedBox(width: 10),
              Text(
                'Change Password',
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: _pwFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPwField(
                  controller: _currentPwController,
                  label: 'Current Password',
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setDialogState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _buildPwField(
                  controller: _newPwController,
                  label: 'New Password',
                  obscure: _obscureNew,
                  onToggle: () =>
                      setDialogState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildPwField(
                  controller: _confirmPwController,
                  label: 'Confirm New Password',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setDialogState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _newPwController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.textMuted)),
            ),
            StatefulBuilder(
              builder: (ctx2, setSaveState) => ElevatedButton(
                onPressed: _isChangingPw
                    ? null
                    : () async {
                        if (!_pwFormKey.currentState!.validate()) return;
                        setSaveState(() => _isChangingPw = true);
                        try {
                          final user = _auth.currentUser!;
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: _currentPwController.text,
                          );
                          await user.reauthenticateWithCredential(cred);
                          await user.updatePassword(_newPwController.text);
                          if (mounted) {
                            Navigator.pop(ctx);
                            _showSnackbar('Password changed successfully!', AppTheme.emerald);
                          }
                        } on FirebaseAuthException catch (e) {
                          if (mounted) {
                            _showSnackbar(
                              e.code == 'wrong-password'
                                  ? 'Current password is incorrect'
                                  : 'Error: ${e.message}',
                              AppTheme.red,
                            );
                          }
                        } catch (e) {
                          if (mounted) _showSnackbar('Error: $e', AppTheme.red);
                        }
                        if (mounted) setSaveState(() => _isChangingPw = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.amber,
                  foregroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: _isChangingPw
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.surface),
                      )
                    : Text('Update',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPwField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.amber, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppTheme.textMuted,
            size: 18,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
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
        errorStyle: const TextStyle(color: AppTheme.redLight, fontSize: 11),
      ),
    );
  }

  // ─── Auth actions ───────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(RouteManager.signin, (route) => false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
              color: AppTheme.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (_user != null) {
      try {
        await _firestore.collection('Users').doc(_user!.uid).delete();
        await _user!.delete();
        await _logout();
      } catch (e) {
        if (mounted) _showSnackbar('Account Deletion Failed: $e', AppTheme.red);
      }
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showOrbs: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  // ─── Shimmer skeleton ───────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Avatar area
          Center(
            child: Column(
              children: [
                const _ShimmerBox(height: 100, isCircle: true),
                const SizedBox(height: 14),
                const _ShimmerBox(width: 160, height: 20),
                const SizedBox(height: 8),
                const _ShimmerBox(width: 120, height: 14),
                const SizedBox(height: 10),
                const _ShimmerBox(width: 120, height: 24, borderRadius: 20),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Info card skeleton
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: AppTheme.radiusXl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ShimmerBox(width: 160, height: 18),
                const SizedBox(height: 20),
                const _ShimmerBox(height: 52),
                const SizedBox(height: 12),
                const _ShimmerBox(height: 52),
                const SizedBox(height: 12),
                const _ShimmerBox(height: 52),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Actions skeleton
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppTheme.radiusXl,
            child: Column(
              children: [
                const _ShimmerBox(height: 52),
                const SizedBox(height: 8),
                const _ShimmerBox(height: 1),
                const SizedBox(height: 8),
                const _ShimmerBox(height: 52),
                const SizedBox(height: 8),
                const _ShimmerBox(height: 1),
                const SizedBox(height: 8),
                const _ShimmerBox(height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main content ───────────────────────────────────────────────────────────

  Widget _buildContent() {
    final photoUrl = _userData?['profilePhotoUrl'] as String?;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // ── Avatar card ──
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.amber, width: 2),
                        boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 20),
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: AppTheme.surfaceLight,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(Icons.person, size: 52, color: AppTheme.amber)
                            : null,
                      ),
                    ),
                    // Camera button overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _showPhotoBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.amber,
                            border: Border.all(color: AppTheme.surface, width: 2),
                            boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 10),
                          ),
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.surface,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_rounded,
                                  color: AppTheme.surface, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _usernameController.text.isNotEmpty
                      ? _usernameController.text
                      : 'User Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _emailController.text,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
                  ),
                  child: Text(
                    'CUSTOMER ACCOUNT',
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

          // ── Account info card ──
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: AppTheme.radiusXl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Username',
                  controller: _usernameController,
                  icon: Icons.person_outline_rounded,
                  isEditing: _isEditingUsername,
                  onToggleEdit: () =>
                      setState(() => _isEditingUsername = !_isEditingUsername),
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'Email',
                  controller: _emailController,
                  icon: Icons.alternate_email_rounded,
                  isEditing: false,
                  isReadOnly: true,
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'Phone',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  isEditing: _isEditingPhone,
                  onToggleEdit: () =>
                      setState(() => _isEditingPhone = !_isEditingPhone),
                ),
                if (_isEditingUsername || _isEditingPhone) ...[
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Save Changes',
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    gradient: AppTheme.emeraldGradient,
                    onPressed: _updateUserData,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Change Password card ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppTheme.radiusXl,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.purple.withOpacity(0.15),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: AppTheme.purple, size: 20),
              ),
              title: Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Update your login password',
                style: GoogleFonts.poppins(
                    color: AppTheme.textMuted, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted, size: 14),
              onTap: _showChangePasswordDialog,
            ),
          ),

          const SizedBox(height: 20),

          // ── Actions card ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppTheme.radiusXl,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.blue.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: AppTheme.blue, size: 20),
                  ),
                  title: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textMuted, size: 14),
                  onTap: _logout,
                ),
                const Divider(color: AppTheme.glassBorder, height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.red.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: AppTheme.red, size: 20),
                  ),
                  title: Text(
                    'Delete Account',
                    style: GoogleFonts.poppins(
                      color: AppTheme.redLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textMuted, size: 14),
                  onTap: _confirmDeleteAccount,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Field builder ──────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    bool isReadOnly = false,
    VoidCallback? onToggleEdit,
  }) {
    return TextFormField(
      controller: controller,
      enabled: isEditing,
      readOnly: isReadOnly,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.amber, size: 20),
        suffixIcon: !isReadOnly
            ? IconButton(
                icon: Icon(
                  isEditing
                      ? Icons.check_circle_outline_rounded
                      : Icons.edit_outlined,
                  color: isEditing ? AppTheme.emerald : AppTheme.amber,
                  size: 20,
                ),
                onPressed: onToggleEdit,
              )
            : const Icon(Icons.lock_outline_rounded,
                color: AppTheme.textMuted, size: 18),
        filled: true,
        fillColor:
            isEditing ? const Color(0x1AFFFFFF) : const Color(0x0EFFFFFF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: isEditing
                ? AppTheme.amber.withOpacity(0.6)
                : AppTheme.glassBorder,
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
