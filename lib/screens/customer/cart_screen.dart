import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> removeFromCart(String productId) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.uid)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return GradientScaffold(
        showOrbs: false,
        body: const Center(
          child: Text("Please sign in to view your cart.", style: TextStyle(color: AppTheme.textPrimary)),
        ),
      );
    }

    return GradientScaffold(
      showOrbs: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pushReplacementNamed(context, RouteManager.home),
        ),
        title: Text(
          "Shopping Cart",
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
              .collection('Users')
              .doc(user!.uid)
              .collection('cart')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
            }

            var items = snapshot.data!.docs;

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.glass,
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Your cart is empty",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Looks like you haven't added any building materials yet.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        child: GradientButton(
                          label: "Browse Stocks",
                          icon: Icons.storefront_outlined,
                          gradient: AppTheme.amberGradient,
                          onPressed: () => Navigator.pushReplacementNamed(context, RouteManager.stocks),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Real-time calculation of total from snapshot
            num totalAmount = 0;
            for (var doc in items) {
              totalAmount += (doc['totalPrice'] ?? 0);
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) => removeFromCart(item.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: AppTheme.radiusLg,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    color: AppTheme.surfaceLight,
                                    child: Image.network(
                                      item['image_url'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, color: AppTheme.textMuted),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0x18FFFFFF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Qty: ${item['quantity']}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹${item['totalPrice']}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.redLight),
                                  onPressed: () => removeFromCart(item.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Checkout Panel
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
                    border: const Border(top: BorderSide(color: AppTheme.glassBorder)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Subtotal (${items.length} ${items.length == 1 ? 'item' : 'items'})",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              "₹$totalAmount",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        GradientButton(
                          label: "Proceed to Buy",
                          icon: Icons.shopping_cart_checkout_rounded,
                          gradient: AppTheme.amberGradient,
                          onPressed: () => Navigator.pushNamed(context, RouteManager.order),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
