import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'driver_details_screen.dart';
import 'add_drivers_screen.dart';

class Drivers extends StatelessWidget {
  const Drivers({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'free':
        return AppTheme.emerald;
      case 'working':
        return AppTheme.amber;
      case 'leave':
        return AppTheme.red;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showOrbs: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Driver Fleet',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.amber.withOpacity(0.18),
                border: Border.all(color: AppTheme.amber.withOpacity(0.4)),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.amber, size: 18),
            ),
            tooltip: 'Add Driver',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDrivers()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('role', isEqualTo: 'driver')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading drivers.', style: GoogleFonts.poppins(color: AppTheme.red)),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
            }

            final drivers = snapshot.data!.docs;

            if (drivers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.badge_outlined, size: 54, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No drivers registered yet.',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: drivers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final driver = drivers[index];
                final name = driver['username'] ?? 'Unknown Driver';
                final phone = driver['phone'] ?? 'N/A';
                final status = driver['status'] ?? 'free';
                final todayJobs = driver['todayJobs'] ?? 0;
                final statusColor = _getStatusColor(status);

                return BentGlassCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverDetails(driverId: driver.id),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(14),
                  borderRadius: AppTheme.radiusLg,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.surfaceLight,
                          child: Icon(Icons.person, color: AppTheme.amber, size: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Jobs Today: $todayJobs",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
