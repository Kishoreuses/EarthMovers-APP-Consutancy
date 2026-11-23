import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class MyOrdersOrRentings extends StatefulWidget {
  const MyOrdersOrRentings({Key? key}) : super(key: key);

  @override
  _MyOrdersOrRentingsState createState() => _MyOrdersOrRentingsState();
}

class _MyOrdersOrRentingsState extends State<MyOrdersOrRentings> with SingleTickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  String searchQuery = '';

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

  Future<void> updateOrderStatus(String docId, String newStatus) async {
    if (user == null) return;

    try {
      // Update in driver's assigned orders subcollection
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .collection('orders')
          .doc(docId)
          .update({
        'status': newStatus,
        'statusTimestamps.$newStatus': Timestamp.now(),
      });

      // Also try updating in root orders collection if doc exists
      try {
        await FirebaseFirestore.instance.collection('orders').doc(docId).update({
          'status': newStatus,
          'statusTimestamps.$newStatus': Timestamp.now(),
        });
      } catch (_) {}

      if (newStatus == "Delivered") {
        await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({
          'status': 'free',
          'todayJobs': FieldValue.increment(1),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Order marked as Delivered! You are now Free."),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating order status: $e");
    }
  }

  Future<void> updateRentingStatus(String docId, String newStatus) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .collection('rented')
          .doc(docId)
          .update({
        'status': newStatus,
        'statusTimestamps.$newStatus': Timestamp.now(),
      });

      try {
        await FirebaseFirestore.instance.collection('rented').doc(docId).update({
          'status': newStatus,
          'statusTimestamps.$newStatus': Timestamp.now(),
        });
      } catch (_) {}

      if (newStatus == "Returned") {
        await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({
          'status': 'free',
          'todayJobs': FieldValue.increment(1),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Machinery marked as Returned! You are now Free."),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating rental status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return GradientScaffold(
        showOrbs: false,
        body: const Center(
          child: Text("Please sign in to view assigned tasks", style: TextStyle(color: AppTheme.textPrimary)),
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
          'My Assigned Jobs',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
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
              ),
              labelColor: const Color(0xFF1A1A2E),
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.local_shipping_outlined, size: 18), text: "Material Deliveries"),
                Tab(icon: Icon(Icons.agriculture_outlined, size: 18), text: "Machine Rentals"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksList('orders'),
          _buildTasksList('rented'),
        ],
      ),
    );
  }

  Widget _buildTasksList(String type) {
    bool isOrder = type == 'orders';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .collection(type)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
        }

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOrder ? Icons.local_shipping_outlined : Icons.agriculture_outlined,
                  size: 54,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  isOrder ? "No material deliveries assigned" : "No vehicle rentals assigned",
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildTaskCard(data, doc.id, type);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String docId, String type) {
    bool isOrder = type == 'orders';
    String currentStatus = data['status'] ?? (isOrder ? 'Pending' : 'Pending');
    List<String> orderStatuses = ["Shipped", "On the way", "Delivered"];
    List<String> rentStatuses = ["On the way", "Returned"];
    List<String> statusOptions = isOrder ? orderStatuses : rentStatuses;

    Color statusColor = AppTheme.amber;
    if (currentStatus.toLowerCase() == 'delivered' || currentStatus.toLowerCase() == 'returned') {
      statusColor = AppTheme.emerald;
    } else if (currentStatus.toLowerCase() == 'on the way' || currentStatus.toLowerCase() == 'shipped') {
      statusColor = AppTheme.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: AppTheme.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top title & status pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['name'] ?? data['productName'] ?? 'Task Item',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    currentStatus.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (data['address'] != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['address'],
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            const Divider(color: AppTheme.glassBorder),
            const SizedBox(height: 8),

            // Status Update Selector
            if (statusOptions.contains(currentStatus) || currentStatus == 'Pending') ...[
              Row(
                children: [
                  Text(
                    "Update Status: ",
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppTheme.surfaceLight,
                        value: statusOptions.contains(currentStatus) ? currentStatus : null,
                        hint: Text(
                          "Select Status",
                          style: GoogleFonts.poppins(color: AppTheme.amber, fontSize: 12),
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.amber),
                        items: statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != currentStatus) {
                            if (isOrder) {
                              updateOrderStatus(docId, val);
                            } else {
                              updateRentingStatus(docId, val);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
