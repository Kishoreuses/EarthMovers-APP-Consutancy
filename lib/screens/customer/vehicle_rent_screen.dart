import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class VehicleRent extends StatefulWidget {
  const VehicleRent({Key? key}) : super(key: key);

  @override
  _VehicleRentState createState() => _VehicleRentState();
}

class _VehicleRentState extends State<VehicleRent> {
  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'title': 'JCB Excavator',
        'subtitle': 'Earth moving, trenching & foundation digging',
        'tag': 'HEAVY DUTY',
        'image': 'images/jcb.jpg',
        'route': RouteManager.jcbStock,
        'accent': AppTheme.amber,
      },
      {
        'title': 'Tractors',
        'subtitle': 'Agricultural hauling, tilling & site clearing',
        'tag': 'HAULING',
        'image': 'images/tractors.png',
        'route': RouteManager.tractorStock,
        'accent': AppTheme.blue,
      },
      {
        'title': 'Tipper Trucks',
        'subtitle': 'Bulk aggregates, gravel & sand transport',
        'tag': 'TRANSPORT',
        'image': 'images/tippers.png',
        'route': RouteManager.tipperStock,
        'accent': AppTheme.emerald,
      },
    ];

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
          'Vehicle Rentals',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final accent = cat['accent'] as Color;

            return BentGlassCard(
              onTap: () => Navigator.pushNamed(context, cat['route'] as String),
              borderColor: accent.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Photo with Gradient Overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          color: AppTheme.surfaceLight,
                          child: Image.asset(
                            cat['image'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.agriculture_rounded, size: 48, color: AppTheme.textMuted)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            cat['tag'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Vehicle Details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat['subtitle'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Rent",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                            ],
                          ),
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
}
