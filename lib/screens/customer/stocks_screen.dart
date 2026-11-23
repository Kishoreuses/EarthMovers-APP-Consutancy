import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/routes/route_manager.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'package:earthmovers_app/core/widgets/shimmer_loading.dart';

class Stocks extends StatefulWidget {
  const Stocks({Key? key}) : super(key: key);

  @override
  _StocksState createState() => _StocksState();
}

class _StocksState extends State<Stocks> {
  User? user = FirebaseAuth.instance.currentUser;
  String searchQuery = "";
  Map<String, int> productQuantities = {};

  Future<void> addToCart(DocumentSnapshot product) async {
    int quantity = productQuantities[product.id] ?? 1;
    num unitPrice = product['pricePerUnit'] ?? 0;
    num totalPrice = unitPrice * quantity;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .collection('cart')
          .doc(product.id)
          .set({
        'name': product['name'],
        'pricePerUnit': unitPrice,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'image_url': product['image_url'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${product['name']} added to cart!"),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  void navigateToOrderPage(DocumentSnapshot product) {
    int quantity = productQuantities[product.id] ?? 1;
    Navigator.pushNamed(
      context,
      RouteManager.order,
      arguments: {
        'product': product,
        'quantity': quantity,
      },
    );
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
          onPressed: () => Navigator.pushReplacementNamed(context, RouteManager.home),
        ),
        title: Text(
          "Building Materials",
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
                color: AppTheme.glass,
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.amber, size: 20),
            ),
            onPressed: () => Navigator.pushNamed(context, RouteManager.cart),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.glass,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase().trim();
                    });
                  },
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Search materials (sand, gravel, bricks)...",
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.amber, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),

            // Products Stream
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('Products').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return _buildLoadingGrid();
                  }

                  var products = snapshot.data!.docs.where((product) {
                    return product['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery);
                  }).toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            "No materials found",
                            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var product = products[index];
                      String productId = product.id;

                      if (!productQuantities.containsKey(productId)) {
                        productQuantities[productId] = 1;
                      }

                      int quantity = productQuantities[productId]!;
                      String name = product['name'] ?? 'Product';
                      num unitPrice = product['pricePerUnit'] ?? 0;
                      num totalPrice = unitPrice * quantity;
                      bool isAvailable = product['availability'] ?? true;
                      bool isBricks = name.toLowerCase().contains('bricks');
                      bool isGravel = name.toLowerCase().contains('gravel') ||
                          name.toLowerCase().contains('karungal');

                      return GlassCard(
                        padding: const EdgeInsets.all(10),
                        borderRadius: AppTheme.radiusLg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image with Availability Badge
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  child: Container(
                                    height: 110,
                                    width: double.infinity,
                                    color: AppTheme.surfaceLight,
                                    child: Image.network(
                                      product['image_url'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(
                                            child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted),
                                          ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isAvailable ? AppTheme.emerald.withOpacity(0.85) : AppTheme.red.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAvailable ? 'IN STOCK' : 'OUT',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Product Title
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Extra Load info if applicable
                            if (isBricks || isGravel) ...[
                              Text(
                                "Load: ${product['Load'] ?? 'N/A'}",
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],

                            const SizedBox(height: 2),

                            // Total Price
                            Text(
                              "₹$totalPrice",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: AppTheme.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),

                            // Quantity Stepper
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0x18FFFFFF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 18,
                                    icon: const Icon(Icons.remove, color: AppTheme.textSecondary),
                                    onPressed: quantity > 1
                                        ? () {
                                            setState(() {
                                              productQuantities[productId] = quantity - 1;
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '$quantity',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 18,
                                    icon: const Icon(Icons.add, color: AppTheme.amber),
                                    onPressed: () {
                                      setState(() {
                                        productQuantities[productId] = quantity + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Action Buttons: Add & Buy
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: isAvailable ? () => addToCart(product) : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isAvailable ? AppTheme.amber.withOpacity(0.18) : Colors.white10,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isAvailable ? AppTheme.amber.withOpacity(0.4) : Colors.transparent,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Add",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isAvailable ? AppTheme.amber : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: InkWell(
                                    onTap: isAvailable ? () => navigateToOrderPage(product) : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient: isAvailable ? AppTheme.emeraldGradient : null,
                                        color: isAvailable ? null : Colors.white10,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Buy",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isAvailable ? Colors.white : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerLoading(width: 150, height: 230),
    );
  }
}
