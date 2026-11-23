import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class OrderAndRentingDetails extends StatefulWidget {
  const OrderAndRentingDetails({Key? key}) : super(key: key);

  @override
  _OrderAndRentingDetailsState createState() => _OrderAndRentingDetailsState();
}

class _OrderAndRentingDetailsState extends State<OrderAndRentingDetails>
    with TickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  // Incremented on pull-to-refresh to force stream rebuild via key
  int _ordersRefreshKey = 0;
  int _rentalsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    if (mounted) setState(() => _ordersRefreshKey++);
    // Small delay so the indicator feels smooth
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _refreshRentals() async {
    if (mounted) setState(() => _rentalsRefreshKey++);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return GradientScaffold(
        showOrbs: false,
        body: const Center(
          child: Text("Please sign in to view your orders", style: TextStyle(color: AppTheme.textPrimary)),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Orders & Rentals",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppTheme.glass,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppTheme.amberGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.glowShadow(AppTheme.amber, blur: 8),
              ),
              labelColor: const Color(0xFF1A1A2E),
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: "Material Orders"),
                Tab(text: "Machine Rentals"),
              ],
            ),
          ),
        ),
      ),
      // AnimatedSwitcher on TabBarView for smooth tab-switch transitions
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: TabBarView(
          key: const ValueKey('tabview'),
          controller: _tabController,
          children: [
            _buildOrdersTab(),
            _buildRentalsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      color: AppTheme.amber,
      backgroundColor: AppTheme.surface,
      onRefresh: _refreshOrders,
      child: StreamBuilder(
        // Key forces stream to re-subscribe on refresh
        key: ValueKey('orders_$_ordersRefreshKey'),
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.receipt_long_outlined,
              title: "No orders found",
              subtitle: "Your placed building material orders will appear here.",
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            itemBuilder: (context, index) => _AnimatedCard(
              index: index,
              child: _buildTrackingCard(docs[index], isRental: false),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRentalsTab() {
    return RefreshIndicator(
      color: AppTheme.amber,
      backgroundColor: AppTheme.surface,
      onRefresh: _refreshRentals,
      child: StreamBuilder(
        key: ValueKey('rentals_$_rentalsRefreshKey'),
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .collection('rented')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.agriculture_outlined,
              title: "No rentals found",
              subtitle: "Vehicles and machinery you rent will appear here.",
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            itemBuilder: (context, index) => _AnimatedCard(
              index: index,
              child: _buildTrackingCard(docs[index], isRental: true),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.glass,
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Icon(icon, size: 54, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(DocumentSnapshot doc, {bool isRental = false}) {
    List<String> orderSteps = ['Order Placed', 'Shipped', 'On the way', 'Delivered'];
    List<String> rentalSteps = ['Pending', 'Rented', 'Returned'];

    String status = doc['status'] ?? (isRental ? 'Pending' : 'Order Placed');
    final steps = isRental ? rentalSteps : orderSteps;
    int currentStep = steps.indexWhere((step) => step.toLowerCase() == status.toLowerCase());
    if (currentStep < 0) currentStep = 0;
    final statusTimestamps = doc['statusTimestamps'] ?? {};

    Color statusColor;
    if (status.toLowerCase().contains('delivered') || status.toLowerCase().contains('returned')) {
      statusColor = AppTheme.emerald;
    } else if (status.toLowerCase().contains('pending') || status.toLowerCase().contains('order placed')) {
      statusColor = AppTheme.amber;
    } else {
      statusColor = AppTheme.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: AppTheme.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge & Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "₹${doc['totalPrice'] ?? 0}",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Item Thumbnail & Details
            Row(
              children: [
                if (doc['image_url'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: AppTheme.surfaceLight,
                      child: Image.network(
                        doc['image_url'],
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
                        doc['name'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (!isRental)
                        Text(
                          "Quantity: ${doc['quantity'] ?? 1}",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      if (isRental && doc['hour'] != null)
                        Text(
                          "Booked: ${doc['hour']} Hours",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      if (isRental && doc['No'] != null)
                        Text(
                          "Vehicle No: ${doc['No']}",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.blueLight),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Driver and Admin Contact chips if available
            if (doc['driverName'] != null && doc['driverName'] != 'Soon') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, size: 16, color: AppTheme.blue),
                    const SizedBox(width: 6),
                    Text(
                      "Driver: ${doc['driverName']} • ${doc['driverPhone'] ?? ''}",
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.blueLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            const SizedBox(height: 6),
            const Divider(color: AppTheme.glassBorder),
            const SizedBox(height: 8),

            // Step Progress Timeline
            Column(
              children: List.generate(steps.length, (index) {
                final stepName = steps[index];
                final isDone = index <= currentStep;
                final isCurrent = index == currentStep;
                final timestamp = statusTimestamps[stepName];
                String timeLabel = '';
                if (timestamp != null && timestamp is Timestamp) {
                  timeLabel = DateFormat('dd MMM, hh:mm a').format(timestamp.toDate());
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? statusColor : Colors.white12,
                          border: Border.all(
                            color: isDone ? statusColor : AppTheme.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isDone ? Icons.check : Icons.circle,
                            size: isDone ? 13 : 6,
                            color: isDone ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        stepName,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isDone ? AppTheme.textPrimary : AppTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                );
              }),
            ),

            // Download Bill Button if finished
            if ((status.toLowerCase() == 'delivered' && !isRental) ||
                (status.toLowerCase() == 'returned' && isRental)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => generatePdfBill(doc.data() as Map<String, dynamic>, isRental),
                  icon: const Icon(Icons.download_rounded, size: 18, color: AppTheme.amber),
                  label: Text(
                    "Download Invoice PDF",
                    style: GoogleFonts.poppins(
                      color: AppTheme.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> generatePdfBill(Map<String, dynamic> data, bool isRental) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = formatter.format(now);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Kadavul Earthmovers", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Date: $formattedDate"),
            pw.SizedBox(height: 10),
            pw.Text("Customer Name: ${data['customerName'] ?? 'Customer'}"),
            pw.Text("Phone: ${data['customerPhone'] ?? 'N/A'}"),
            pw.Text("Address: ${data['address'] ?? 'N/A'}"),
            pw.SizedBox(height: 10),
            if (data['adminName'] != null && data['adminPhone'] != null)
              pw.Text("Manager: ${data['adminName']} (${data['adminPhone']})"),
            pw.Divider(),
            pw.Text("Item: ${data['name']}"),
            if (!isRental) pw.Text("Quantity: ${data['quantity']}"),
            pw.Text("Total Price: INR ${data['totalPrice']}"),
            if (isRental) ...[
              pw.Text("Vehicle No: ${data['No'] ?? 'N/A'}"),
              pw.Text("Total Hours Booked: ${data['hour'] ?? 'N/A'}"),
            ],
            pw.SizedBox(height: 20),
            pw.Text("Thank you for choosing Kadavul Earthmovers!", style: const pw.TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );

    // Android 13+ (API 33+): Permission.storage is no longer granted.
    // Try storage first, then manageExternalStorage, then fall back to app docs dir.
    PermissionStatus status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    // Even if still denied, we try the Downloads dir (works on API 29+ without permission)
    // and fall back to app documents directory.

    Directory? dir;
    try {
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File("${dir.path}/Invoice_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invoice saved to ${file.path}"),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Staggered fade+slide entrance animation for each card in the list.
class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Stagger: each card delays by index * 80ms (capped at 400ms so long lists don't lag)
    final delay = Duration(milliseconds: (widget.index * 80).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
