import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class DriverDetails extends StatefulWidget {
  final String driverId;

  const DriverDetails({required this.driverId, super.key});

  @override
  State<DriverDetails> createState() => _DriverDetailsState();
}

class _DriverDetailsState extends State<DriverDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleDriverLogic(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    bool available = data['available'] ?? true;
    String status = data['status'] ?? 'free';
    Timestamp? lastReset = data['lastJobReset'] as Timestamp?;

    final now = DateTime.now();
    final resetTime = lastReset?.toDate() ?? now;

    if (now.difference(resetTime).inHours >= 24) {
      await _firestore.collection('Users').doc(widget.driverId).update({
        'todayJobs': 0,
        'lastJobReset': Timestamp.fromDate(now),
      });
    }

    if (available == false && status != 'leave') {
      await _firestore.collection('Users').doc(widget.driverId).update({
        'status': 'leave',
        'todayJobs': 0,
      });
    }
  }

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
          'Driver Profile & Duty',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('Users').doc(widget.driverId).get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load driver data', style: GoogleFonts.poppins(color: AppTheme.red)),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
            }

            final driverData = snapshot.data!.data() as Map<String, dynamic>?;
            if (driverData == null) {
              return Center(
                child: Text('Driver not found', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
              );
            }

            _handleDriverLogic(snapshot.data!);

            String name = driverData['username'] ?? 'Unknown Driver';
            String phone = driverData['phone'] ?? 'N/A';
            String email = driverData['email'] ?? 'N/A';
            String status = driverData['status'] ?? 'free';
            int todayJobs = driverData['todayJobs'] ?? 0;
            bool isAvailable = driverData['available'] ?? true;
            Color statusColor = _getStatusColor(status);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Driver Avatar Card
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor, width: 2),
                            boxShadow: AppTheme.glowShadow(statusColor, blur: 20),
                          ),
                          child: const CircleAvatar(
                            radius: 46,
                            backgroundColor: AppTheme.surfaceLight,
                            child: Icon(Icons.person, size: 52, color: AppTheme.amber),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Driver Details GlassCard
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: AppTheme.radiusXl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Driver Information",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoTile(Icons.phone_outlined, "Phone Number", phone),
                        const Divider(color: AppTheme.glassBorder, height: 20),
                        _buildInfoTile(Icons.email_outlined, "Email Address", email),
                        const Divider(color: AppTheme.glassBorder, height: 20),
                        _buildInfoTile(
                          Icons.local_shipping_outlined,
                          "Tasks Completed Today",
                          "$todayJobs Jobs",
                          valueColor: AppTheme.amber,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Duty / Availability Status Toggle GlassCard
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: AppTheme.radiusXl,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Active Duty Status",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              isAvailable ? "Available for assignments" : "Marked on leave",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isAvailable ? AppTheme.emeraldLight : AppTheme.redLight,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isAvailable,
                          activeColor: AppTheme.emerald,
                          inactiveTrackColor: AppTheme.red.withOpacity(0.4),
                          onChanged: (bool newValue) async {
                            await _firestore.collection('Users').doc(widget.driverId).update({
                              'available': newValue,
                              'status': newValue ? 'free' : 'leave',
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x14FFFFFF),
          ),
          child: Icon(icon, color: AppTheme.amber, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
