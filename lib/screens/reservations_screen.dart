import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/device_service.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Niet ingelogd'));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: Color(0xFFF7F5F0),
            floating: true,
            elevation: 0,
            titleSpacing: 20,
            title: Text(
              'Mijn reserveringen',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: DeviceService().getMyReservations(user.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
                  ),
                );
              }
              if (snap.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.orange,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Index aanmaken in Firebase:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snap.error}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final reservations = snap.data ?? [];
              if (reservations.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Color(0xFFB0A99E),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nog geen reserveringen',
                          style: TextStyle(
                            color: Color(0xFF6B6560),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Reserveer een toestel via Ontdekken',
                          style: TextStyle(color: Color(0xFF9E9890)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ReservationCard(data: reservations[i]),
                    childCount: reservations.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReservationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Veilige datum parsing zonder locale crash
    String dateText = '';
    try {
      final fmt = DateFormat('dd MMM yyyy', 'nl_BE');
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      dateText = '${fmt.format(start)} → ${fmt.format(end)}';
    } catch (_) {
      dateText = 'Datum onbekend';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.devices,
              color: Color(0xFF2D6A4F),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['deviceTitle'] ?? 'Toestel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Color(0xFF6B6560),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['status'] ?? 'bevestigd',
              style: const TextStyle(
                color: Color(0xFF2D6A4F),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
