import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({Key? key}) : super(key: key);

  @override
  _DriverHomeState createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final User? user = FirebaseAuth.instance.currentUser;
  String driverName = 'Driver';
  String driverStatus = 'free';
  int newOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDriverInfo();
    _getNewOrdersCount();
  }

  Future<void> _fetchDriverInfo() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          driverName = doc['username'] ?? 'Driver';
          driverStatus = doc['status'] ?? 'free';
        });
      }
    }
  }

  Future<void> _getNewOrdersCount() async {
    if (user != null) {
      try {
        var snapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .collection('orders')
            .where('status', isNotEqualTo: 'Delivered')
            .get();

        if (mounted) {
          setState(() {
            newOrdersCount = snapshot.docs.length;
          });
        }
      } catch (e) {
        debugPrint("Error fetching orders count: $e");
      }
    }
  }

  void _navigateTo(String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      showOrbs: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.blue.withOpacity(0.3)),
              ),
              child: Text(
                'DRIVER CONSOLE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blueLight,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hello, $driverName 👋',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.amber, width: 1.5),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.surfaceLight,
                child: Icon(Icons.person, color: AppTheme.amber, size: 16),
              ),
            ),
            onPressed: () => _navigateTo('/driverProfile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Driver Status Banner
              GlassCard(
                gradient: const LinearGradient(
                  colors: [Color(0x333B82F6), Color(0x1010B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppTheme.blue.withOpacity(0.3),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.blue.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.drive_eta_rounded, color: AppTheme.blueLight, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Duty & Assignments",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            "Check assigned dispatch deliveries, update work status, and log tasks.",
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Driver Tools",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Menu Card 1: My Orders
              _buildDriverMenuCard(
                title: "Assigned Deliveries",
                subtitle: "View active material and rental jobs",
                icon: Icons.assignment_outlined,
                badgeCount: newOrdersCount,
                accentColor: AppTheme.amber,
                onTap: () => _navigateTo('/myOrdersOrRentings'),
              ),

              const SizedBox(height: 12),

              // Menu Card 2: My Status
              _buildDriverMenuCard(
                title: "Availability Status",
                subtitle: "Toggle between Free, Busy, or Leave",
                icon: Icons.toggle_on_outlined,
                accentColor: AppTheme.blue,
                onTap: () => _navigateTo('/myStatus'),
              ),

              const SizedBox(height: 12),

              // Menu Card 3: Today's Jobs
              _buildDriverMenuCard(
                title: "Today's Completed Jobs",
                subtitle: "Daily logs and completion records",
                icon: Icons.history_rounded,
                accentColor: AppTheme.emerald,
                onTap: () => _navigateTo('/driverTodayJobs'),
              ),

              const SizedBox(height: 12),

              // Menu Card 4: Driver Profile
              _buildDriverMenuCard(
                title: "Profile & Settings",
                subtitle: "Account credentials and password",
                icon: Icons.person_outline_rounded,
                accentColor: AppTheme.purple,
                onTap: () => _navigateTo('/driverProfile'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return BentGlassCard(
      onTap: onTap,
      borderColor: accentColor.withOpacity(0.3),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.15),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (badgeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount active',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accentColor),
        ],
      ),
    );
  }
}
