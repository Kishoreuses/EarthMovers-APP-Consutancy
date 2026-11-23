import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class MyStatus extends StatefulWidget {
  const MyStatus({Key? key}) : super(key: key);

  @override
  _MyStatusState createState() => _MyStatusState();
}

class _MyStatusState extends State<MyStatus> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? driverId;

  final Map<String, Map<String, dynamic>> statusMapping = {
    'Available': {
      'status': 'free',
      'available': true,
      'color': AppTheme.emerald,
      'icon': Icons.check_circle_outline_rounded,
      'desc': 'Ready to accept incoming delivery assignments',
    },
    'Working': {
      'status': 'busy',
      'available': true,
      'color': AppTheme.amber,
      'icon': Icons.local_shipping_outlined,
      'desc': 'Currently on route with an active job',
    },
    'Leave': {
      'status': 'leave',
      'available': false,
      'color': AppTheme.red,
      'icon': Icons.pause_circle_outline_rounded,
      'desc': 'Off-duty or on leave; not eligible for tasks',
    },
  };

  @override
  void initState() {
    super.initState();
    driverId = _auth.currentUser?.uid;
  }

  Future<void> updateStatus(String label) async {
    if (driverId == null) return;
    final selected = statusMapping[label]!;

    await _firestore.collection('Users').doc(driverId).update({
      'status': selected['status'],
      'available': selected['available'],
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duty status updated to $label'),
          backgroundColor: selected['color'] as Color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (driverId == null) {
      return GradientScaffold(
        showOrbs: false,
        body: const Center(
          child: Text("Driver session not found.", style: TextStyle(color: AppTheme.textPrimary)),
        ),
      );
    }

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
          "Duty Status",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('Users').doc(driverId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final currentStatus = statusMapping.entries
              .firstWhere(
                (entry) => entry.value['status'] == data['status'],
                orElse: () => MapEntry('Available', statusMapping['Available']!),
              )
              .key;

          final activeColor = statusMapping[currentStatus]!['color'] as Color;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Driver Profile Header Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: AppTheme.radiusXl,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: activeColor, width: 2),
                          boxShadow: AppTheme.glowShadow(activeColor, blur: 12),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.surfaceLight,
                          child: Icon(Icons.person, color: activeColor, size: 30),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['username'] ?? 'Driver',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _auth.currentUser?.email ?? '',
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: activeColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          currentStatus.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Set Your Current Duty State",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Interactive Status Option Cards
                ...statusMapping.entries.map((entry) {
                  final label = entry.key;
                  final info = entry.value;
                  final isSelected = currentStatus == label;
                  final color = info['color'] as Color;
                  final icon = info['icon'] as IconData;
                  final desc = info['desc'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: BentGlassCard(
                      onTap: () => updateStatus(label),
                      borderColor: isSelected ? color : AppTheme.glassBorder,
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [color.withOpacity(0.2), const Color(0x101A1A2E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(isSelected ? 0.3 : 0.12),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
