import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class AdminOrderAndRentingDetails extends StatefulWidget {
  const AdminOrderAndRentingDetails({Key? key}) : super(key: key);

  @override
  _AdminOrderAndRentingDetailsState createState() => _AdminOrderAndRentingDetailsState();
}

class _AdminOrderAndRentingDetailsState extends State<AdminOrderAndRentingDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Orders & Dispatch Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 17,
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
              isScrollable: true,
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppTheme.amberGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              labelColor: const Color(0xFF1A1A2E),
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
              tabs: const [
                Tab(text: 'Active Orders'),
                Tab(text: 'Past Orders'),
                Tab(text: 'Active Rentals'),
                Tab(text: 'Past Rentals'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OrdersWidget(isPast: false),
          OrdersWidget(isPast: true),
          RentalsWidget(isPast: false),
          RentalsWidget(isPast: true),
        ],
      ),
    );
  }
}

class OrdersWidget extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool isPast;

  OrdersWidget({Key? key, required this.isPast}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Users').where('role', isEqualTo: 'user').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading users', style: GoogleFonts.poppins(color: AppTheme.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No customers found', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          );
        }
        var users = snapshot.data!.docs;
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: users.map((user) => _buildUserOrders(context, user)).toList(),
        );
      },
    );
  }

  Widget _buildUserOrders(BuildContext context, DocumentSnapshot user) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Users').doc(user.id).collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        try {
          var filteredOrders = snapshot.data!.docs.where((order) {
            var status = order['status']?.toString().toLowerCase() ?? '';
            return isPast ? status == 'delivered' : status != 'delivered';
          }).toList();

          if (filteredOrders.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: AppTheme.radiusLg,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.amber.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: AppTheme.amber, size: 20),
                  ),
                  title: Text(
                    '${user['username']} (${filteredOrders.length})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    user['phone'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  children: filteredOrders
                      .map((order) => _buildOrderItem(context, order, user.id, user))
                      .toList(),
                ),
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildOrderItem(
      BuildContext context, DocumentSnapshot order, String userId, DocumentSnapshot user) {
    final status = order['status'] ?? 'Pending';
    final price = order['totalPrice'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['name'] ?? 'Item',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                "₹$price",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Address: ${order['address'] ?? 'Not specified'}",
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text("Status: ", style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
              if (!isPast)
                _buildStatusDropdown(order, userId)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emeraldLight,
                    ),
                  ),
                ),
            ],
          ),
          if (isPast && order['statusTimestamps'] != null) ...[
            const SizedBox(height: 6),
            _buildStatusTimestamps(order['statusTimestamps']),
          ],
          if (!isPast) ...[
            const SizedBox(height: 8),
            _buildDriverAssignSection(context, order, userId, 'orders'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(DocumentSnapshot order, String userId) {
    return DropdownButton<String>(
      dropdownColor: AppTheme.surfaceLight,
      value: ['Pending', 'Shipped', 'On the way', 'Delivered'].contains(order['status'])
          ? order['status']
          : 'Pending',
      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.amber),
      underline: const SizedBox.shrink(),
      style: GoogleFonts.poppins(color: AppTheme.amber, fontWeight: FontWeight.bold, fontSize: 13),
      items: ['Pending', 'Shipped', 'On the way', 'Delivered'].map((status) {
        return DropdownMenuItem(value: status, child: Text(status));
      }).toList(),
      onChanged: (newStatus) async {
        if (newStatus != null) {
          await _firestore.collection('Users').doc(userId).collection('orders').doc(order.id).update({
            'status': newStatus,
            'statusTimestamps.$newStatus': Timestamp.now(),
          });

          if (newStatus == 'Delivered' && order['driverPhone'] != null) {
            QuerySnapshot snap = await _firestore
                .collection('Users')
                .where('phone', isEqualTo: order['driverPhone'])
                .get();
            if (snap.docs.isNotEmpty) {
              await _firestore.collection('Users').doc(snap.docs.first.id).update({
                'status': 'free',
              });
            }
          }
        }
      },
    );
  }

  Widget _buildDriverAssignSection(
      BuildContext context, DocumentSnapshot order, String userId, String type) {
    String currentDriver = order['driverName'] ?? 'Soon';

    return Row(
      children: [
        Text(
          currentDriver != 'Soon' ? "Driver: $currentDriver" : "No Driver Assigned",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: currentDriver != 'Soon' ? AppTheme.blueLight : AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Users')
              .where('role', isEqualTo: 'driver')
              .where('status', isEqualTo: 'free')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            var drivers = snapshot.data!.docs;
            if (drivers.isEmpty) {
              return Text(
                "No Free Drivers",
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.redLight),
              );
            }

            return PopupMenuButton<String>(
              color: AppTheme.surfaceLight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.amber.withOpacity(0.4)),
                ),
                child: Text(
                  currentDriver != 'Soon' ? "Reassign" : "Assign Driver",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.amber,
                  ),
                ),
              ),
              onSelected: (driverId) {
                _assignDriver(userId, order.id, driverId, order.data() as Map<String, dynamic>, type);
              },
              itemBuilder: (context) {
                return drivers.map((driver) {
                  return PopupMenuItem<String>(
                    value: driver.id,
                    child: Text(
                      "${driver['username']} (${driver['phone'] ?? ''})",
                      style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 12.5),
                    ),
                  );
                }).toList();
              },
            );
          },
        ),
      ],
    );
  }

  void _assignDriver(
      String userId, String docId, String driverId, Map<String, dynamic> data, String type) async {
    DocumentSnapshot driverDoc = await _firestore.collection('Users').doc(driverId).get();

    await _firestore.collection('Users').doc(userId).collection(type).doc(docId).update({
      'driverName': driverDoc['username'],
      'driverPhone': driverDoc['phone'],
    });

    await _firestore.collection('Users').doc(driverId).update({'status': 'working'});

    await _firestore.collection('Users').doc(driverId).collection(type).doc(docId).set({
      ...data,
      'driverName': driverDoc['username'],
      'driverPhone': driverDoc['phone'],
    });
  }

  Widget _buildStatusTimestamps(Map<dynamic, dynamic> timestamps) {
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timestamps.entries.map<Widget>((entry) {
        if (entry.value is Timestamp) {
          Timestamp ts = entry.value;
          return Text(
            '${entry.key}: ${formatter.format(ts.toDate())}',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
          );
        } else {
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}

class RentalsWidget extends OrdersWidget {
  RentalsWidget({Key? key, required bool isPast}) : super(key: key, isPast: isPast);

  @override
  Widget _buildUserOrders(BuildContext context, DocumentSnapshot user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(user.id)
          .collection('rented')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        try {
          var filteredRentals = snapshot.data!.docs.where((rental) {
            var status = rental['status']?.toString().toLowerCase() ?? '';
            return isPast ? status == 'returned' : status != 'returned';
          }).toList();

          if (filteredRentals.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: AppTheme.radiusLg,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.blue.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.agriculture_rounded, color: AppTheme.blue, size: 20),
                  ),
                  title: Text(
                    '${user['username']} Rentals (${filteredRentals.length})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    user['phone'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  children: filteredRentals
                      .map((rental) => _buildRentalItem(context, rental, user.id, user))
                      .toList(),
                ),
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildRentalItem(
      BuildContext context, DocumentSnapshot rental, String userId, DocumentSnapshot user) {
    final status = rental['status'] ?? 'pending';
    final price = rental['totalPrice'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rental['name'] ?? 'Vehicle',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                "₹$price",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Hours: ${rental['hour'] ?? 1} • Reg: ${rental['No'] ?? 'N/A'}",
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            "Site Address: ${rental['address'] ?? 'Not specified'}",
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text("Status: ", style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
              if (!isPast)
                _buildRentalStatusDropdown(rental, userId)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emeraldLight,
                    ),
                  ),
                ),
            ],
          ),
          if (isPast && rental['statusTimestamps'] != null) ...[
            const SizedBox(height: 6),
            _buildStatusTimestamps(rental['statusTimestamps']),
          ],
          if (!isPast) ...[
            const SizedBox(height: 8),
            _buildDriverAssignSection(context, rental, userId, 'rented'),
          ],
        ],
      ),
    );
  }

  Widget _buildRentalStatusDropdown(DocumentSnapshot rental, String userId) {
    String current = rental['status'] ?? 'Pending';
    String matched = ['Pending', 'Rented', 'Returned'].firstWhere(
      (s) => s.toLowerCase() == current.toLowerCase(),
      orElse: () => 'Pending',
    );

    return DropdownButton<String>(
      dropdownColor: AppTheme.surfaceLight,
      value: matched,
      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.amber),
      underline: const SizedBox.shrink(),
      style: GoogleFonts.poppins(color: AppTheme.amber, fontWeight: FontWeight.bold, fontSize: 13),
      items: ['Pending', 'Rented', 'Returned'].map((status) {
        return DropdownMenuItem(value: status, child: Text(status));
      }).toList(),
      onChanged: (newStatus) async {
        if (newStatus != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .collection('rented')
              .doc(rental.id)
              .update({
            'status': newStatus,
            'statusTimestamps.$newStatus': Timestamp.now(),
          });

          if (newStatus == 'Returned' && rental['driverPhone'] != null) {
            QuerySnapshot snap = await FirebaseFirestore.instance
                .collection('Users')
                .where('phone', isEqualTo: rental['driverPhone'])
                .get();
            if (snap.docs.isNotEmpty) {
              await FirebaseFirestore.instance.collection('Users').doc(snap.docs.first.id).update({
                'status': 'free',
              });
            }
          }
        }
      },
    );
  }
}
