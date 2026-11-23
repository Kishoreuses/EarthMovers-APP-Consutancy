import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class AdminJcbStock extends StatefulWidget {
  const AdminJcbStock({Key? key}) : super(key: key);

  @override
  _AdminJcbStockState createState() => _AdminJcbStockState();
}

class _AdminJcbStockState extends State<AdminJcbStock> {
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
          "Manage JCB Fleet",
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
              .where('type', isEqualTo: 'Jcb')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "No JCBs found in inventory",
                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 16),
                ),
              );
            }

            var jcbMachines = snapshot.data!.docs;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: jcbMachines.length,
              itemBuilder: (context, index) {
                var vehicle = jcbMachines[index];
                bool isAvailable = vehicle['availability'] ?? true;
                num price = vehicle['pricePerHour'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: AppTheme.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const Icon(Icons.broken_image, color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vehicle['name'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              "₹$price/hr",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "Reg: ${vehicle['No'] ?? 'N/A'}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.blueLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${vehicle['HP'] ?? 'N/A'} HP",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.glassBorder),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAvailable ? "Rental Status: Available" : "Rental Status: In Use / Rented",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isAvailable ? AppTheme.emeraldLight : AppTheme.redLight,
                              ),
                            ),
                            Switch(
                              value: isAvailable,
                              activeColor: AppTheme.emerald,
                              inactiveTrackColor: AppTheme.red.withOpacity(0.4),
                              onChanged: (bool newValue) {
                                FirebaseFirestore.instance
                                    .collection('Rent')
                                    .doc(vehicle.id)
                                    .update({'availability': newValue});
                              },
                            ),
                          ],
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
