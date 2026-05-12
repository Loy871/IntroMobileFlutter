import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Globale gesimuleerde datum voor testen
class DevClock {
  static DateTime? _simulated;
  static DateTime get now => _simulated ?? DateTime.now();
  static bool get isSimulated => _simulated != null;
  static void set(DateTime d) => _simulated = d;
  static void reset() => _simulated = null;
}

class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});
  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  DateTime _picked = DateTime.now();
  final fmt = DateFormat('dd/MM/yyyy', 'nl');
  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final snap = await FirebaseFirestore.instance
        .collection('reservations')
        .orderBy('startDate')
        .get()
        .catchError(
          (_) => FirebaseFirestore.instance.collection('reservations').get(),
        );
    setState(() {
      _reservations = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _picked,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.green),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _picked = picked);
  }

  String _statusColor(String status) {
    switch (status) {
      case 'goedgekeurd':
        return '✅';
      case 'geannuleerd':
        return '❌';
      case 'geweigerd':
        return '🚫';
      default:
        return '⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = DevClock.isSimulated;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('🛠 Developer tools'),
        backgroundColor: AppTheme.bg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Waarschuwing
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE67F00).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE67F00),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dev tools — alleen voor testen! Verwijder dit scherm voor productie.',
                      style: TextStyle(
                        color: Color(0xFFE67F00),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Datum simulator
            const Text(
              'Datum simulator',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Simuleer een andere datum om te testen wat er gebeurt na het uitlenen.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  // Huidige simulatie status
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE67F00)
                              : AppTheme.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive
                            ? 'Gesimuleerd: ${fmt.format(DevClock.now)}'
                            : 'Echte datum: ${fmt.format(DateTime.now())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? const Color(0xFFE67F00)
                              : AppTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Datum kiezen
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.green,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            fmt.format(_picked),
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Snelknoppen
                  const Text(
                    'Snel naar:',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickBtn(
                        '+1 dag',
                        DateTime.now().add(const Duration(days: 1)),
                      ),
                      _quickBtn(
                        '+3 dagen',
                        DateTime.now().add(const Duration(days: 3)),
                      ),
                      _quickBtn(
                        '+1 week',
                        DateTime.now().add(const Duration(days: 7)),
                      ),
                      _quickBtn(
                        '+2 weken',
                        DateTime.now().add(const Duration(days: 14)),
                      ),
                      _quickBtn(
                        '+1 maand',
                        DateTime.now().add(const Duration(days: 30)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            DevClock.set(_picked);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Datum gesimuleerd: ${fmt.format(_picked)}',
                                ),
                                backgroundColor: const Color(0xFFE67F00),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67F00),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Datum instellen',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            DevClock.reset();
                            setState(() => _picked = DateTime.now());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Terug naar echte datum'),
                                backgroundColor: AppTheme.green,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.greenPale,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.green.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Alle reserveringen overzicht
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alle reserveringen',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppTheme.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _loading = true);
                    _loadReservations();
                  },
                  child: const Icon(
                    Icons.refresh,
                    color: AppTheme.green,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.green),
              )
            else if (_reservations.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: const Text(
                  'Geen reserveringen gevonden',
                  style: TextStyle(color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._reservations.map((r) {
                String startStr = '–', endStr = '–';
                bool isActive = false;
                bool isPast = false;
                try {
                  final start = (r['startDate'] as Timestamp).toDate();
                  final end = (r['endDate'] as Timestamp).toDate();
                  startStr = fmt.format(start);
                  endStr = fmt.format(end);
                  final now = DevClock.now;
                  isActive = !now.isBefore(start) && !now.isAfter(end);
                  isPast = now.isAfter(end);
                } catch (_) {}

                final status = r['status'] ?? 'bevestigd';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFFF8E1)
                        : isPast
                        ? const Color(0xFFF5F5F5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFE67F00).withOpacity(0.3)
                          : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r['deviceTitle'] ?? 'Onbekend toestel',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${_statusColor(status)} $status',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$startStr → $endStr',
                        style: const TextStyle(
                          color: AppTheme.textMid,
                          fontSize: 12,
                        ),
                      ),
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67F00),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🔴 Nu actief (uitgeleen)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (isPast)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.greenPale,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✅ Afgelopen — teruggebracht',
                            style: TextStyle(
                              color: AppTheme.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(String label, DateTime date) => GestureDetector(
    onTap: () => setState(() => _picked = date),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _picked.day == date.day && _picked.month == date.month
            ? AppTheme.green
            : AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _picked.day == date.day && _picked.month == date.month
              ? Colors.white
              : AppTheme.textMid,
        ),
      ),
    ),
  );
}
