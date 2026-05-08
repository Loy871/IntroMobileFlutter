import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../widgets/device_image.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/star_rating.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  final DeviceService service;
  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.service,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isReserving = false;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2D6A4F),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _reserve() async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kies eerst een periode')));
      return;
    }
    setState(() => _isReserving = true);
    try {
      await widget.service.makeReservation(
        deviceId: widget.device.id,
        deviceTitle: widget.device.title,
        ownerId: widget.device.ownerId,
        renterId: auth.uid,
        start: _startDate!,
        end: _endDate!,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservering bevestigd!'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      }
    } catch (e) {
      setState(() => _isReserving = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'nl');
    final device = widget.device;
    final hasLocation = device.lat != 0 && device.lng != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF2D6A4F),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF1A1A1A),
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: DeviceImage(
                imageUrl: device.imageUrl,
                width: double.infinity,
                height: 280,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel + beschikbaarheid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          device.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: device.available
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          device.available ? 'Beschikbaar' : 'Verhuurd',
                          style: TextStyle(
                            color: device.available
                                ? const Color(0xFF2D6A4F)
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Prijs + categorie
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '€${device.pricePerDay} / dag',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          device.category,
                          style: const TextStyle(color: Color(0xFF6B6560)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Beschrijving
                  if (device.description.isNotEmpty) ...[
                    const Text(
                      'Beschrijving',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      device.description,
                      style: const TextStyle(
                        color: Color(0xFF6B6560),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Kaart
                  if (hasLocation) ...[
                    const Text(
                      'Locatie',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (device.city.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF2D6A4F),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              device.city,
                              style: const TextStyle(
                                color: Color(0xFF6B6560),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(device.lat, device.lng),
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.buurtleen.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(device.lat, device.lng),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF2D6A4F),
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Periode kiezen
                  if (device.available) ...[
                    const Text(
                      'Periode kiezen',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _startDate != null
                                ? const Color(0xFF2D6A4F)
                                : const Color(0xFFE0DBD1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF2D6A4F),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${fmt.format(_startDate!)} → ${fmt.format(_endDate!)}'
                                  : 'Tik om een periode te kiezen',
                              style: TextStyle(
                                color: _startDate != null
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFFB0A99E),
                                fontWeight: _startDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_startDate != null && _endDate != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Totale prijs:',
                              style: TextStyle(color: Color(0xFF6B6560)),
                            ),
                            Text(
                              '€${(device.pricePerDay * (_endDate!.difference(_startDate!).inDays + 1)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF2D6A4F),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    GestureDetector(
                      onTap: _isReserving ? null : _reserve,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isReserving
                              ? const Color(0xFF9E9890)
                              : const Color(0xFF2D6A4F),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _isReserving
                            ? const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Text(
                                'Reserveer nu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEBE4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Momenteel niet beschikbaar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9E9890),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Text(
                    'Beoordelingen',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Beoordeling schrijven
                  _ReviewForm(
                    deviceId: widget.device.id,
                    service: widget.service,
                  ),
                  const SizedBox(height: 16),

                  // Bestaande beoordelingen
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.service.getReviews(widget.device.id),
                    builder: (context, snap) {
                      final reviews = snap.data ?? [];
                      if (reviews.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration(),
                          child: const Text(
                            'Nog geen beoordelingen',
                            style: TextStyle(color: AppTheme.textLight),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: reviews
                            .map((r) => _ReviewCard(data: r))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  final String deviceId;
  final DeviceService service;
  const _ReviewForm({required this.deviceId, required this.service});

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _comment = TextEditingController();
  double _rating = 0;
  bool _loading = false;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geef een score')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await widget.service.submitReview(
        deviceId: widget.deviceId,
        reviewerId: user.uid,
        reviewerName: user.email?.split('@').first ?? 'Gebruiker',
        rating: _rating,
        comment: _comment.text.trim(),
      );
      _comment.clear();
      setState(() => _rating = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beoordeling geplaatst!'),
            backgroundColor: AppTheme.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          const Text(
            'Schrijf een beoordeling',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          InteractiveStarRating(onChanged: (r) => setState(() => _rating = r)),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 2,
            style: const TextStyle(color: AppTheme.textDark),
            decoration: AppTheme.inputDecoration('Vertel over je ervaring...'),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Beoordeling plaatsen',
            loading: _loading,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['reviewerName'] ?? 'Gebruiker',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  fontSize: 13,
                ),
              ),
              StarRating(rating: (data['rating'] as num).toDouble()),
            ],
          ),
          if ((data['comment'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data['comment'],
              style: const TextStyle(
                color: AppTheme.textMid,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
