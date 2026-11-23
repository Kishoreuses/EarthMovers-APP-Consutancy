import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'package:earthmovers_app/core/widgets/shimmer_loading.dart';

class AdminStocks extends StatefulWidget {
  const AdminStocks({Key? key}) : super(key: key);

  @override
  _AdminStocksState createState() => _AdminStocksState();
}

class _AdminStocksState extends State<AdminStocks> {
  String searchQuery = "";

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
          "Manage Materials Stock",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
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
                    hintText: "Search materials by name...",
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
                    return product['name'].toString().toLowerCase().contains(searchQuery);
                  }).toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 54, color: AppTheme.textMuted),
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
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var product = products[index];
                      bool isAvailable = product['availability'] ?? true;
                      final priceController = TextEditingController(
                        text: (product['pricePerUnit'] ?? 0).toString(),
                      );

                      return GlassCard(
                        padding: const EdgeInsets.all(10),
                        borderRadius: AppTheme.radiusLg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              child: Container(
                                height: 100,
                                width: double.infinity,
                                color: AppTheme.surfaceLight,
                                child: Image.network(
                                  product['image_url'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, color: AppTheme.textMuted),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Product Title
                            Text(
                              product['name'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            // Price Input
                            Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0x14FFFFFF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      "₹",
                                      style: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: priceController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      onSubmitted: (newValue) {
                                        num? newPrice = num.tryParse(newValue);
                                        if (newPrice != null) {
                                          FirebaseFirestore.instance
                                              .collection('Products')
                                              .doc(product.id)
                                              .update({'pricePerUnit': newPrice});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Price updated to ₹$newPrice"),
                                              backgroundColor: AppTheme.emerald,
                                              duration: const Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Availability Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAvailable ? "In Stock" : "Out of Stock",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isAvailable ? AppTheme.emeraldLight : AppTheme.redLight,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: isAvailable,
                                    activeColor: AppTheme.emerald,
                                    inactiveTrackColor: AppTheme.red.withOpacity(0.4),
                                    onChanged: (bool newValue) {
                                      FirebaseFirestore.instance
                                          .collection('Products')
                                          .doc(product.id)
                                          .update({'availability': newValue});
                                    },
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerLoading(width: 150, height: 230),
    );
  }
}
