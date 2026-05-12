import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/device_image.dart';
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
  List<DateTimeRange> _blockedPeriods = [];
  bool _loadingPeriods = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedPeriods();
  }

  Future<void> _loadBlockedPeriods() async {
    final periods = await widget.service.getBlockedPeriods(widget.device.id);
    setState(() {
      _blockedPeriods = periods;
      _loadingPeriods = false;
    });
  }

  /// Geeft true als een dag geblokkeerd is
  bool _isDayBlocked(DateTime day) {
    for (final p in _blockedPeriods) {
      if (!day.isBefore(p.start) && !day.isAfter(p.end)) {
        return true;
      }
    }
    return false;
  }

  /// Geeft true als een geselecteerde range een geblokkeerde dag bevat
  bool _rangeHasBlockedDay(DateTime start, DateTime end) {
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (_isDayBlocked(current)) return true;
      current = current.add(const Duration(days: 1));
    }
    return false;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      // Nieuwe signature: 3 parameters
      selectableDayPredicate: (day, start, end) => !_isDayBlocked(day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.green,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
          // disabledDayStyle bestaat niet meer, verwijderd
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (_rangeHasBlockedDay(picked.start, picked.end)) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Periode bevat al gereserveerde dagen'),
              backgroundColor: AppTheme.red,
            ),
          );
        return;
      }
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
            backgroundColor: AppTheme.green,
          ),
        );
      }
    } on Exception catch (e) {
      setState(() => _isReserving = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'nl');
    final device = widget.device;
    final hasLocation = device.lat != 0 && device.lng != 0;
    final days = _startDate != null && _endDate != null
        ? _endDate!.difference(_startDate!).inDays + 1
        : 0;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // Hero foto header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.green,
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
                  color: AppTheme.textDark,
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
                  // Titel + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          device.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
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
                              ? AppTheme.greenPale
                              : AppTheme.redPale,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          device.available ? 'Beschikbaar' : 'Verhuurd',
                          style: TextStyle(
                            color: device.available
                                ? AppTheme.green
                                : AppTheme.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  if (device.avgRating > 0) ...[
                    StarRating(
                      rating: device.avgRating,
                      count: device.reviewCount,
                      size: 16,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Prijs + categorie
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.green,
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
                          style: const TextStyle(color: AppTheme.textMid),
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
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      device.description,
                      style: const TextStyle(
                        color: AppTheme.textMid,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Geblokkeerde periodes tonen
                  if (_blockedPeriods.isNotEmpty) ...[
                    const Text(
                      'Niet beschikbaar op:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _blockedPeriods.map((p) {
                        final f = DateFormat('dd MMM', 'nl');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.redPale,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.red.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.block,
                                size: 12,
                                color: AppTheme.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.start.isAtSameMomentAs(p.end)
                                    ? f.format(p.start)
                                    : '${f.format(p.start)} – ${f.format(p.end)}',
                                style: const TextStyle(
                                  color: AppTheme.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                        color: AppTheme.textDark,
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
                              color: AppTheme.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              device.city,
                              style: const TextStyle(
                                color: AppTheme.textMid,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
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
                                    color: AppTheme.green,
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

                  // Datumkiezer
                  if (device.available) ...[
                    const Text(
                      'Periode kiezen',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Laad indicator voor periodes
                    if (_loadingPeriods)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.cardDecoration(),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.green,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Beschikbaarheid laden...',
                              style: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _startDate != null
                                  ? AppTheme.green
                                  : AppTheme.border,
                              width: _startDate != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenPale,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.green,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _startDate != null && _endDate != null
                                          ? '${fmt.format(_startDate!)} → ${fmt.format(_endDate!)}'
                                          : 'Tik om een periode te kiezen',
                                      style: TextStyle(
                                        color: _startDate != null
                                            ? AppTheme.textDark
                                            : AppTheme.textLight,
                                        fontWeight: _startDate != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (_blockedPeriods.isNotEmpty)
                                      const Text(
                                        'Grijze dagen zijn al gereserveerd',
                                        style: TextStyle(
                                          color: AppTheme.textLight,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppTheme.textLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Totaalprijs
                    if (_startDate != null && _endDate != null && days > 0)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.greenPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Totale prijs',
                                  style: TextStyle(
                                    color: AppTheme.textMid,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '$days dag${days > 1 ? 'en' : ''}',
                                  style: const TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '€${(device.pricePerDay * days).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.green,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    AppButton(
                      label: _startDate == null
                          ? 'Kies eerst een periode'
                          : 'Reserveer nu',
                      loading: _isReserving,
                      onTap: _startDate != null ? _reserve : null,
                      icon: Icons.check_circle_outline_rounded,
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
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Beoordelingen
                  const Text(
                    'Beoordelingen',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ReviewForm(
                    deviceId: widget.device.id,
                    service: widget.service,
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.service.getReviews(widget.device.id),
                    builder: (context, snap) {
                      final reviews = snap.data ?? [];
                      if (reviews.isEmpty) {
                        return Container(
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

// Review widgets
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beoordeling geplaatst!'),
            backgroundColor: AppTheme.green,
          ),
        );
    } on Exception catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.red,
          ),
        );
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
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.greenPale,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (data['reviewerName'] as String? ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data['reviewerName'] ?? 'Gebruiker',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      fontSize: 13,
                    ),
                  ),
                ],
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
