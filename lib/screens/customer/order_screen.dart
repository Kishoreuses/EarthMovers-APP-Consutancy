import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/animated_button.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';
import 'home_screen.dart';

class Order extends StatefulWidget {
  const Order({Key? key}) : super(key: key);

  @override
  _OrderState createState() => _OrderState();
}

class _OrderState extends State<Order> {
  final TextEditingController _addressController = TextEditingController();
  String? _currentLocation;
  bool _isLoading = false;
  bool _isLocating = false;
  bool _isPlacingOrder = false;
  final User? user = FirebaseAuth.instance.currentUser;

  List<DocumentSnapshot> cartItems = [];
  Map<String, dynamic>? buyingProduct;
  int buyingQuantity = 1;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('product')) {
      buyingProduct = (args['product'] as DocumentSnapshot).data() as Map<String, dynamic>?;
      if (buyingProduct != null) {
        buyingProduct!['id'] = args['product'].id;
      }
      buyingQuantity = args['quantity'] ?? 1;
      setState(() {});
    } else {
      _fetchCurrentUserCart();
    }
  }

  Future<void> _fetchCurrentUserCart() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    var snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.uid)
        .collection('cart')
        .get();
    if (mounted) {
      setState(() {
        cartItems = snapshot.docs;
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Please enable location services in device settings"),
              backgroundColor: AppTheme.amber,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Location permission denied"),
                backgroundColor: AppTheme.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      String fullAddress =
          "${place.name ?? ''}, ${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}";

      if (mounted) {
        setState(() {
          _currentLocation = fullAddress;
          _addressController.text = fullAddress;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to fetch current location"),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => _isLocating = false);
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty && _currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter delivery address or share your location"),
          backgroundColor: AppTheme.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (user == null) return;
    setState(() => _isPlacingOrder = true);

    String address = _currentLocation ?? _addressController.text.trim();

    try {
      if (buyingProduct != null) {
        String orderId = FirebaseFirestore.instance.collection('orders').doc().id;
        num pricePerUnit = buyingProduct!['pricePerUnit'] ?? 0;
        num totalPrice = pricePerUnit * buyingQuantity;

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .collection('orders')
            .doc(orderId)
            .set({
          'orderId': orderId,
          'name': buyingProduct!['name'],
          'image_url': buyingProduct!['image_url'],
          'quantity': buyingQuantity,
          'totalPrice': totalPrice,
          'address': address,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Pending',
          'driverName': 'Soon',
          'driverPhone': '0000000000',
          'statusTimestamps': {
            'Order Placed': FieldValue.serverTimestamp(),
            'Shipped': null,
            'On the way': null,
            'Delivered': null,
          },
        });
      } else {
        for (var item in cartItems) {
          String orderId = FirebaseFirestore.instance.collection('orders').doc().id;
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.uid)
              .collection('orders')
              .doc(orderId)
              .set({
            'orderId': orderId,
            'name': item['name'],
            'image_url': item['image_url'],
            'quantity': item['quantity'],
            'totalPrice': item['totalPrice'],
            'address': address,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Pending',
            'driverName': 'Soon',
            'driverPhone': '0000000000',
            'adminName': 'Kishore',
            'adminPhone': 919677871881,
            'statusTimestamps': {
              'Order Placed': FieldValue.serverTimestamp(),
              'Shipped': null,
              'On the way': null,
              'Delivered': null,
            },
          });
        }

        for (var item in cartItems) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.uid)
              .collection('cart')
              .doc(item.id)
              .delete();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Order Placed Successfully!"),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to place order: $e"),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) setState(() => _isPlacingOrder = false);
  }

  @override
  Widget build(BuildContext context) {
    final isBuyingNow = buyingProduct != null;

    num grandTotal = 0;
    if (isBuyingNow) {
      grandTotal = (buyingProduct!['pricePerUnit'] ?? 0) * buyingQuantity;
    } else {
      for (var item in cartItems) {
        grandTotal += (item['totalPrice'] ?? 0);
      }
    }

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
          "Order Checkout",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading && !isBuyingNow
            ? const Center(child: CircularProgressIndicator(color: AppTheme.amber))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Delivery Badge / Hero Banner
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0x33F59E0B), Color(0x111A1A2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.amber.withOpacity(0.15),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              color: AppTheme.amber,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Doorstep Delivery",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  "Fast dispatch with live status tracking",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delivery Address GlassCard
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
                                "Delivery Address",
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
                              hintText: "Enter full delivery address or landmarks...",
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
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _isLocating ? null : _getCurrentLocation,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: AppTheme.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isLocating
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.blue,
                                          ),
                                        )
                                      : const Icon(Icons.my_location_rounded, color: AppTheme.blue, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isLocating ? "Fetching location..." : "Use Current Location",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Items Overview
                    Text(
                      "Items Summary",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (isBuyingNow)
                      _buildSummaryItem(
                        name: buyingProduct!['name'] ?? '',
                        imageUrl: buyingProduct!['image_url'] ?? '',
                        quantity: buyingQuantity,
                        price: (buyingProduct!['pricePerUnit'] ?? 0) * buyingQuantity,
                      )
                    else if (cartItems.isEmpty)
                      Center(
                        child: Text(
                          "No items found",
                          style: GoogleFonts.poppins(color: AppTheme.textMuted),
                        ),
                      )
                    else
                      ...cartItems.map((item) {
                        return _buildSummaryItem(
                          name: item['name'] ?? '',
                          imageUrl: item['image_url'] ?? '',
                          quantity: item['quantity'] ?? 1,
                          price: item['totalPrice'] ?? 0,
                        );
                      }).toList(),

                    const SizedBox(height: 16),

                    // Price Breakdown GlassCard
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: AppTheme.radiusLg,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Payable",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                "₹$grandTotal",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.amber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                "Payment will be coordinated upon dispatch",
                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Place Order Button
                    GradientButton(
                      label: "Place Order",
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isPlacingOrder,
                      gradient: AppTheme.emeraldGradient,
                      onPressed: _placeOrder,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String name,
    required String imageUrl,
    required int quantity,
    required num price,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: AppTheme.radiusMd,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                width: 58,
                height: 58,
                color: AppTheme.surfaceLight,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: AppTheme.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Quantity: $quantity",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "₹$price",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
