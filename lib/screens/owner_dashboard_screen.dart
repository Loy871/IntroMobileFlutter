import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/device_image.dart';
import '../widgets/app_button.dart';
import 'add_device_screen.dart';
import 'edit_device_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Niet ingelogd'));
    final db = FirebaseFirestore.instance;
    final service = DeviceService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
        ),
        backgroundColor: AppTheme.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Toestel toevoegen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: AppTheme.bg,
            floating: true,
            elevation: 0,
            titleSpacing: 20,
            title: Text(
              'Mijn aanbod',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),

          // Sectie: mijn toestellen
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.devices_rounded,
                    color: AppTheme.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Mijn toestellen',
                    style: TextStyle(
                      color: AppTheme.textMid,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('devices')
                .where('ownerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppTheme.green),
                    ),
                  ),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.greenPale,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.devices_other_rounded,
                            size: 40,
                            color: AppTheme.greenLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Nog niets aangeboden',
                          style: TextStyle(
                            color: AppTheme.textMid,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Voeg je eerste toestel toe via de knop onderaan',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final device = Device.fromMap(d, docs[i].id);
                  return _OwnDeviceCard(
                    device: device,
                    service: service,
                    onDelete: () => _confirmDelete(context, service, device.id),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDeviceScreen(device: device),
                      ),
                    ),
                  );
                }, childCount: docs.length),
              );
            },
          ),

          // Sectie: inkomende reserveringen
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.inbox_rounded,
                    color: AppTheme.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Inkomende reserveringen',
                    style: TextStyle(
                      color: AppTheme.textMid,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('reservations')
                .where('ownerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(),
                    child: const Text(
                      'Nog geen inkomende reserveringen',
                      style: TextStyle(color: AppTheme.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return _IncomingCard(data: d, docId: docs[i].id);
                  }, childCount: docs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DeviceService service, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Toestel verwijderen?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Dit verwijdert het toestel permanent uit het aanbod.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuleren',
              style: TextStyle(color: AppTheme.textMid),
            ),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteDevice(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Verwijderen',
              style: TextStyle(color: AppTheme.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnDeviceCard extends StatelessWidget {
  final Device device;
  final DeviceService service;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _OwnDeviceCard({
    required this.device,
    required this.service,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: DeviceImage(imageUrl: device.imageUrl),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '€${device.pricePerDay}/dag · ${device.category}',
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statusBadge(device.available),
                          const Spacer(),
                          // Toggle beschikbaarheid
                          GestureDetector(
                            onTap: () => service.updateDevice(device.id, {
                              'available': !device.available,
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                device.available
                                    ? 'Verhuur stoppen'
                                    : 'Activeren',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMid,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Acties onderaan kaart
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: AppTheme.green,
                    ),
                    label: const Text(
                      'Bewerken',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 32, color: AppTheme.border),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: AppTheme.red,
                    ),
                    label: const Text(
                      'Verwijderen',
                      style: TextStyle(
                        color: AppTheme.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool available) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: available ? AppTheme.greenPale : AppTheme.redPale,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      available ? 'Beschikbaar' : 'Verhuurd',
      style: TextStyle(
        color: available ? AppTheme.green : AppTheme.red,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _IncomingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _IncomingCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM', 'nl');
    String dateText = '';
    try {
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      dateText = '${fmt.format(start)} → ${fmt.format(end)}';
    } catch (_) {}
    final status = data['status'] ?? 'bevestigd';
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'goedgekeurd':
        statusColor = AppTheme.green;
        statusBg = AppTheme.greenPale;
        break;
      case 'geweigerd':
        statusColor = AppTheme.red;
        statusBg = AppTheme.redPale;
        break;
      default:
        statusColor = const Color(0xFFE67F00);
        statusBg = const Color(0xFFFFF3E0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['deviceTitle'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    fontSize: 14,
                  ),
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
          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppTheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  dateText,
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 12),
                ),
              ],
            ),
          ],
          if (status == 'bevestigd') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => FirebaseFirestore.instance
                        .collection('reservations')
                        .doc(docId)
                        .update({'status': 'goedgekeurd'}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Goedkeuren',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FirebaseFirestore.instance
                        .collection('reservations')
                        .doc(docId)
                        .update({'status': 'geweigerd'}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.redPale,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Weigeren',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
