import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'package:earthmovers_app/core/widgets/shimmer_loading.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _username = "User";
  String _email = "user@example.com";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    _user = _auth.currentUser;
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("Users")
            .doc(_user!.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _username = userDoc["username"] ?? "User";
            _email = _user!.email ?? "user@example.com";
          });
        }
      } catch (e) {
        debugPrint("Error fetching user: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateTo(String routeName) {
    if (!_isLoading) {
      Navigator.pushNamed(context, routeName);
    }
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
            Text(
              'Welcome back 👋',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _username,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.glass,
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.amber, size: 20),
            ),
            onPressed: () => _navigateTo(RouteManager.cart),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _navigateTo(RouteManager.profile),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.amber, width: 1.5),
                  boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 8),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.surfaceLight,
                  child: Icon(Icons.person, size: 20, color: AppTheme.amber),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingSkeleton()
            : RefreshIndicator(
                color: AppTheme.amber,
                backgroundColor: AppTheme.surface,
                onRefresh: () async {
                  setState(() => _isLoading = true);
                  await _getCurrentUser();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header Banner Card
                    GlassCard(
                      gradient: const LinearGradient(
                        colors: [Color(0x33F59E0B), Color(0x111A1A2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderColor: AppTheme.amber.withOpacity(0.3),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'OFFICIAL SERVICE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.amber,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kadavul Earthmovers',
                                  style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quality materials and dependable heavy equipment on demand.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.amber.withOpacity(0.12),
                              border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
                            ),
                            child: const Icon(
                              Icons.construction_rounded,
                              color: AppTheme.amber,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Explore Services',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Feature Card 1: Building Materials Stocks
                    _buildServiceCard(
                      title: 'Building Materials',
                      subtitle: 'Blue metal, M-sand, gravel & aggregates',
                      badge: 'STOCKS',
                      imagePath: 'images/materials.jpg',
                      accentColor: AppTheme.amber,
                      accentGradient: AppTheme.amberGradient,
                      onTap: () => _navigateTo(RouteManager.stocks),
                    ),

                    const SizedBox(height: 14),

                    // Feature Card 2: Renting Vehicles
                    _buildServiceCard(
                      title: 'Vehicle Rentals',
                      subtitle: 'JCB, Tractors & Tippers with experienced operators',
                      badge: 'FLEET',
                      imagePath: 'images/vehicles.jpg',
                      accentColor: AppTheme.blue,
                      accentGradient: AppTheme.blueGradient,
                      onTap: () => _navigateTo(RouteManager.vehicleRent),
                    ),

                    const SizedBox(height: 14),

                    // Feature Card 3: Orders & Rents
                    _buildServiceCard(
                      title: 'My Orders & Rentals',
                      subtitle: 'Live status tracking, history & details',
                      badge: 'TRACKING',
                      imagePath: 'images/orders.png',
                      accentColor: AppTheme.emerald,
                      accentGradient: AppTheme.emeraldGradient,
                      onTap: () => _navigateTo(RouteManager.orderAndRentingDetails),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          ShimmerLoading(width: double.infinity, height: 120, borderRadius: 20),
          SizedBox(height: 20),
          ShimmerLoading(width: double.infinity, height: 140, borderRadius: 20),
          SizedBox(height: 14),
          ShimmerLoading(width: double.infinity, height: 140, borderRadius: 20),
          SizedBox(height: 14),
          ShimmerLoading(width: double.infinity, height: 140, borderRadius: 20),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required String badge,
    required String imagePath,
    required Color accentColor,
    required Gradient accentGradient,
    required VoidCallback onTap,
  }) {
    return BentGlassCard(
      onTap: onTap,
      borderColor: accentColor.withOpacity(0.25),
      child: Stack(
        children: [
          // Background soft tint
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Thumbnail with rounded glass frame
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.glassBorder),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.surfaceLight,
                        child: Icon(Icons.image_not_supported, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Card text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accentColor.withOpacity(0.3), width: 0.8),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Right arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF24243E), Color(0xFF16162A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: AppTheme.glassBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.amber, width: 2),
                      boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 10),
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.surfaceLight,
                      child: Icon(Icons.person, size: 30, color: AppTheme.amber),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Items
            _buildDrawerTile(
              icon: Icons.person_outline_rounded,
              title: 'Profile Settings',
              onTap: () {
                Navigator.pop(context);
                _navigateTo(RouteManager.profile);
              },
            ),
            _buildDrawerTile(
              icon: Icons.inventory_2_outlined,
              title: 'Materials Stock',
              onTap: () {
                Navigator.pop(context);
                _navigateTo(RouteManager.stocks);
              },
            ),
            _buildDrawerTile(
              icon: Icons.agriculture_outlined,
              title: 'Rent Vehicles',
              onTap: () {
                Navigator.pop(context);
                _navigateTo(RouteManager.vehicleRent);
              },
            ),
            _buildDrawerTile(
              icon: Icons.receipt_long_outlined,
              title: 'Orders & Rentals',
              onTap: () {
                Navigator.pop(context);
                _navigateTo(RouteManager.orderAndRentingDetails);
              },
            ),

            const Spacer(),
            const Divider(color: AppTheme.glassBorder),

            // Logout
            _buildDrawerTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              color: AppTheme.red,
              onTap: () async {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteManager.signin,
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppTheme.textPrimary;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: itemColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
