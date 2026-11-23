import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'renting_screen.dart';

class TractorStock extends StatefulWidget {
  const TractorStock({Key? key}) : super(key: key);

  @override
  _TractorStockState createState() => _TractorStockState();
}

class _TractorStockState extends State<TractorStock> {
  Map<String, int> hoursSelected = {};

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
          "Rent Tractors",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Rent')
              .where('type', isEqualTo: 'tractor')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.blue));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.agriculture_outlined, size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      "No Tractors currently available",
                      style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }

            var tractorMachines = snapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: tractorMachines.length,
              itemBuilder: (context, index) {
                var vehicle = tractorMachines[index];
                if (!hoursSelected.containsKey(vehicle.id)) {
                  hoursSelected[vehicle.id] = 1;
                }

                int hours = hoursSelected[vehicle.id]!;
                num pricePerHour = vehicle['pricePerHour'] ?? 0;
                num totalPrice = pricePerHour * hours;
                bool isAvailable = vehicle['availability'] ?? true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: AppTheme.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Image with Availability Badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                color: AppTheme.surfaceLight,
                                child: Image.network(
                                  vehicle['image_url'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Icon(Icons.broken_image, color: AppTheme.textMuted)),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAvailable ? AppTheme.emerald.withOpacity(0.9) : AppTheme.red.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isAvailable ? 'AVAILABLE' : 'RENTED OUT',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title & Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                vehicle['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              "₹$pricePerHour/hr",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.blueLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.blue.withOpacity(0.3)),
                              ),
                              child: Text(
                                "Reg: ${vehicle['No'] ?? 'N/A'}",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.blueLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x14FFFFFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${vehicle['HP'] ?? 'N/A'} HP",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Hours Selector & Total
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x10FFFFFF),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Hours: ",
                                    style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.textMuted, size: 22),
                                    onPressed: hours > 1
                                        ? () => setState(() => hoursSelected[vehicle.id] = hours - 1)
                                        : null,
                                  ),
                                  Text(
                                    "$hours",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.blue, size: 22),
                                    onPressed: () => setState(() => hoursSelected[vehicle.id] = hours + 1),
                                  ),
                                ],
                              ),
                              Text(
                                "Total: ₹$totalPrice",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.blueLight,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Rent CTA Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isAvailable
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Renting(
                                          vehicle: vehicle,
                                          hours: hoursSelected[vehicle.id]!,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAvailable ? AppTheme.blue : Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                              elevation: isAvailable ? 4 : 0,
                            ),
                            child: Text(
                              isAvailable ? "Proceed to Rent" : "Currently Unavailable",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
