import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Niet ingelogd'));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: AppTheme.bg,
            floating: true,
            elevation: 0,
            titleSpacing: 20,
            title: Text(
              'Mijn huurders',
              style: TextStyle(
                color: AppTheme.textDark,
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
                    child: CircularProgressIndicator(color: AppTheme.green),
                  ),
                );
              }
              final all = snap.data ?? [];

              // Splits in actief en verleden
              final now = DateTime.now();
              final active = all.where((r) {
                try {
                  final end = (r['endDate'] as Timestamp).toDate();
                  return end.isAfter(now) &&
                      r['status'] != 'geannuleerd' &&
                      r['status'] != 'geweigerd';
                } catch (_) {
                  return false;
                }
              }).toList();
              final past = all.where((r) {
                try {
                  final end = (r['endDate'] as Timestamp).toDate();
                  return end.isBefore(now) ||
                      r['status'] == 'geannuleerd' ||
                      r['status'] == 'geweigerd';
                } catch (_) {
                  return false;
                }
              }).toList();

              if (all.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nog geen reserveringen',
                          style: TextStyle(
                            color: AppTheme.textMid,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Reserveer een toestel via Ontdekken',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (active.isNotEmpty) ...[
                      _sectionHeader(
                        'Actieve reserveringen',
                        Icons.check_circle_outline,
                      ),
                      ...active.map(
                        (r) => _ReservationCard(data: r, canCancel: true),
                      ),
                    ],
                    if (past.isNotEmpty) ...[
                      _sectionHeader('Vorige reserveringen', Icons.history),
                      ...past.map(
                        (r) => _ReservationCard(data: r, canCancel: false),
                      ),
                    ],
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.green),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMid,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canCancel;
  const _ReservationCard({required this.data, required this.canCancel});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'nl');
    String dateText = '';
    int days = 0;
    try {
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      dateText = '${fmt.format(start)} → ${fmt.format(end)}';
      days = end.difference(start).inDays + 1;
    } catch (_) {}

    final status = data['status'] ?? 'bevestigd';
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (status) {
      case 'goedgekeurd':
        statusColor = AppTheme.green;
        statusBg = AppTheme.greenPale;
        statusIcon = Icons.check_circle;
        break;
      case 'geannuleerd':
        statusColor = AppTheme.textLight;
        statusBg = const Color(0xFFF5F5F5);
        statusIcon = Icons.cancel;
        break;
      case 'geweigerd':
        statusColor = AppTheme.red;
        statusBg = AppTheme.redPale;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = const Color(0xFFE67F00);
        statusBg = const Color(0xFFFFF3E0);
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['deviceTitle'] ?? 'Toestel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                      if (dateText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          dateText,
                          style: const TextStyle(
                            color: AppTheme.textMid,
                            fontSize: 12,
                          ),
                        ),
                        if (days > 0)
                          Text(
                            '$days dag${days > 1 ? 'en' : ''}',
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Annuleer knop
          if (canCancel && status != 'geannuleerd') ...[
            Container(height: 1, color: AppTheme.border),
            TextButton.icon(
              onPressed: () => _confirmCancel(context),
              icon: const Icon(
                Icons.cancel_outlined,
                size: 15,
                color: AppTheme.red,
              ),
              label: const Text(
                'Annuleer reservering',
                style: TextStyle(
                  color: AppTheme.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reservering annuleren?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Weet je zeker dat je deze reservering wil annuleren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Terug',
              style: TextStyle(color: AppTheme.textMid),
            ),
          ),
          TextButton(
            onPressed: () async {
              await DeviceService().cancelReservation(data['id']);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Annuleren',
              style: TextStyle(color: AppTheme.red),
            ),
          ),
        ],
      ),
    );
  }
}
