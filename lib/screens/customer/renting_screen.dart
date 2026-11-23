import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class Renting extends StatefulWidget {
  final DocumentSnapshot vehicle;
  final int hours;

  const Renting({Key? key, required this.vehicle, required this.hours}) : super(key: key);

  @override
  _RentingState createState() => _RentingState();
}

class _RentingState extends State<Renting> {
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _addressController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> confirmRent() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter destination/worksite address"),
          backgroundColor: AppTheme.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (user == null) return;
    setState(() => isLoading = true);

    num pricePerHour = widget.vehicle['pricePerHour'] ?? 0;
    num totalPrice = pricePerHour * widget.hours;
    String rentedId = FirebaseFirestore.instance.collection('rented').doc().id;

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .collection('rented')
          .doc(rentedId)
          .set({
        'rentedId': rentedId,
        'userId': user!.uid,
        'name': widget.vehicle['name'],
        'image_url': widget.vehicle['image_url'],
        'HP': widget.vehicle['HP'],
        'pricePerHour': pricePerHour,
        'hour': widget.hours,
        'totalPrice': totalPrice,
        'address': _addressController.text.trim(),
        'rentedAt': Timestamp.now(),
        'No': widget.vehicle['No'],
        'status': 'pending',
        'driverName': 'Soon',
        'driverPhone': '0000000000',
        'statusTimestamps': {
          "Pending": FieldValue.serverTimestamp(),
          "Rented": null,
          "Returned": null,
        },
        'adminName': 'Kishore',
        'adminPhone': 919677871881,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.vehicle['name']} rented successfully!"),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, RouteManager.home, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to book rental: $e"),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    num pricePerHour = widget.vehicle['pricePerHour'] ?? 0;
    num totalPrice = pricePerHour * widget.hours;

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
          "Confirm Rental",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle Overview Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppTheme.radiusLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: AppTheme.surfaceLight,
                        child: Image.network(
                          widget.vehicle['image_url'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.agriculture_rounded, size: 48, color: AppTheme.textMuted)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.vehicle['name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
                            "Reg: ${widget.vehicle['No'] ?? 'N/A'}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
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
                            "${widget.vehicle['HP'] ?? 'N/A'} HP",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Booking Details Breakdown Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppTheme.radiusLg,
                child: Column(
                  children: [
                    _buildRow("Rate per Hour", "₹$pricePerHour"),
                    const Divider(color: AppTheme.glassBorder, height: 20),
                    _buildRow("Duration", "${widget.hours} ${widget.hours == 1 ? 'Hour' : 'Hours'}"),
                    const Divider(color: AppTheme.glassBorder, height: 20),
                    _buildRow(
                      "Estimated Total",
                      "₹$totalPrice",
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Worksite / Delivery Location
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppTheme.radiusLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Worksite / Delivery Address",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter the site location or address...",
                        hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0x14FFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Rental CTA
              GradientButton(
                label: "Confirm & Book Machinery",
                icon: Icons.check_circle_outline_rounded,
                isLoading: isLoading,
                gradient: AppTheme.amberGradient,
                onPressed: confirmRent,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isHighlighted ? 15 : 13,
            color: isHighlighted ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? AppTheme.amber : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
