import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:earthmovers_app/core/theme/app_theme.dart';
import 'package:earthmovers_app/core/widgets/glass_card.dart';
import 'package:earthmovers_app/core/widgets/gradient_scaffold.dart';

class DriverTodayJobs extends StatelessWidget {
  DriverTodayJobs({Key? key}) : super(key: key);

  final User? user = FirebaseAuth.instance.currentUser;

  Stream<List<Map<String, dynamic>>> fetchTodayJobs() async* {
    if (user == null) {
      yield [];
      return;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final ordersStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.uid)
        .collection('orders')
        .snapshots();

    final rentingsStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.uid)
        .collection('rented')
        .snapshots();

    await for (final orderSnapshot in ordersStream) {
      final rentingSnapshot = await rentingsStream.first;

      final allJobs = <Map<String, dynamic>>[];

      for (final doc in orderSnapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp?)?.toDate();

        if (data['status'] == 'Delivered') {
          if (completedAt != null &&
              completedAt.isAfter(startOfDay) &&
              completedAt.isBefore(endOfDay)) {
            allJobs.add({...data, 'type': 'Material Order', 'id': doc.id});
          }
        } else {
          allJobs.add({...data, 'type': 'Material Order', 'id': doc.id});
        }
      }

      for (final doc in rentingSnapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp?)?.toDate();

        if (data['status'] == 'Returned') {
          if (completedAt != null &&
              completedAt.isAfter(startOfDay) &&
              completedAt.isBefore(endOfDay)) {
            allJobs.add({...data, 'type': 'Machinery Rental', 'id': doc.id});
          }
        } else {
          allJobs.add({...data, 'type': 'Machinery Rental', 'id': doc.id});
        }
      }

      yield allJobs;
    }
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd MMM, hh:mm a').format(date);
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
          "Today's Completed Tasks",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: fetchTodayJobs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
            }

            final jobs = snapshot.data!;

            if (jobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_alt_rounded, size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks completed today yet',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                final isCompleted =
                    job['status'] == 'Delivered' || job['status'] == 'Returned';
                final statusColor = isCompleted ? AppTheme.emerald : AppTheme.amber;

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: AppTheme.radiusLg,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withOpacity(0.18),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['name'] ?? job['productName'] ?? 'Task Item',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job['type'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppTheme.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (job['address'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Site: ${job['address']}",
                                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                            if (isCompleted && job['completedAt'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Completed: ${formatDate(job['completedAt'])}",
                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.emeraldLight),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (job['status'] ?? 'Active').toString().toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
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
