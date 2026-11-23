import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {

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
                color: AppTheme.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
              ),
              child: Text(
                'ADMIN CONSOLE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.amber,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Business Control Panel',
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
                boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 8),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.surfaceLight,
                child: Icon(Icons.shield_outlined, color: AppTheme.amber, size: 16),
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, RouteManager.adminProfile),
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
              // Welcome Banner
              GlassCard(
                gradient: const LinearGradient(
                  colors: [Color(0x33F59E0B), Color(0x103B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppTheme.amber.withOpacity(0.3),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.amber.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.amber, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Fleet & Inventory Hub",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            "Manage materials pricing, heavy machinery, driver assignments and customer orders.",
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
                "Management Modules",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 2x2 Grid of Management Modules
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
                children: [
                  _buildAdminTile(
                    title: 'Building Materials',
                    subtitle: 'Price & Stock',
                    icon: Icons.inventory_2_rounded,
                    imagePath: 'images/materials.jpg',
                    accentColor: AppTheme.amber,
                    onTap: () => Navigator.pushNamed(context, RouteManager.adminStocks),
                  ),
                  _buildAdminTile(
                    title: 'Vehicle Fleet',
                    subtitle: 'Rental Machines',
                    icon: Icons.agriculture_rounded,
                    imagePath: 'images/vehicles.jpg',
                    accentColor: AppTheme.blue,
                    onTap: () => Navigator.pushNamed(context, RouteManager.adminVehicleRent),
                  ),
                  _buildAdminTile(
                    title: 'Customer Orders',
                    subtitle: 'Track & Dispatch',
                    icon: Icons.receipt_long_rounded,
                    imagePath: 'images/orders.png',
                    accentColor: AppTheme.emerald,
                    onTap: () => Navigator.pushNamed(context, RouteManager.adminOrderAndRentingDetails),
                  ),
                  _buildAdminTile(
                    title: 'Driver Fleet',
                    subtitle: 'Staff & Contacts',
                    icon: Icons.badge_rounded,
                    imagePath: 'images/drivers.jpg',
                    accentColor: AppTheme.purple,
                    onTap: () => Navigator.pushNamed(context, RouteManager.drivers),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String imagePath,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return BentGlassCard(
      onTap: onTap,
      borderColor: accentColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
            child: Container(
              height: 95,
              width: double.infinity,
              color: AppTheme.surfaceLight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Center(child: Icon(icon, color: accentColor, size: 36)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppTheme.surface.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surface.withOpacity(0.8),
                        border: Border.all(color: accentColor.withOpacity(0.4)),
                      ),
                      child: Icon(icon, color: accentColor, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Label Area
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
