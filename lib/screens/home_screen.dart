import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../models/device.dart';
import 'add_device_screen.dart';
import 'reservations_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/device_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _deviceService = DeviceService();
  String _selectedCategory = 'Alles';
  int _tabIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Alles', 'icon': Icons.apps},
    {'label': 'Tuin', 'icon': Icons.grass},
    {'label': 'Keuken', 'icon': Icons.blender},
    {'label': 'Schoonmaak', 'icon': Icons.cleaning_services},
    {'label': 'Gereedschap', 'icon': Icons.build},
    {'label': 'Overig', 'icon': Icons.category},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: _tabIndex == 0 ? _buildBrowse() : const ReservationsScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEBE4), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF2D6A4F),
          unselectedItemColor: const Color(0xFFB0A99E),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Ontdekken',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Reserveringen',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
              ),
              backgroundColor: const Color(0xFF2D6A4F),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBrowse() {
    final auth = Provider.of<AuthService>(context, listen: false);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFF7F5F0),
          floating: true,
          snap: true,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BuurtLeen',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const Text(
                    'Deel met je buurt',
                    style: TextStyle(color: Color(0xFF9E9890), fontSize: 12),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => auth.logout(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0DBD1)),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF6B6560),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat['label'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat['label']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2D6A4F)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF2D6A4F)
                                : const Color(0xFFE0DBD1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF6B6560),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'],
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B6560),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        StreamBuilder<List<Device>>(
          stream: _deviceService.getDevices(category: _selectedCategory),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
                ),
              );
            }
            final devices = snap.data ?? [];
            if (devices.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9E0),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.devices_other,
                          size: 48,
                          color: Color(0xFF9E9890),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Geen toestellen gevonden',
                        style: TextStyle(
                          color: Color(0xFF6B6560),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Voeg zelf een toestel toe!',
                        style: TextStyle(color: Color(0xFF9E9890)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) =>
                      _DeviceCard(device: devices[i], service: _deviceService),
                  childCount: devices.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final DeviceService service;
  const _DeviceCard({required this.device, required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: DeviceImage(imageUrl: device.imageUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '€${device.pricePerDay}/dag',
                          style: const TextStyle(
                            color: Color(0xFF2D6A4F),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        device.category,
                        style: const TextStyle(
                          color: Color(0xFFB0A99E),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final startDate = DateTime.now().add(const Duration(days: 1));
    final endDate = startDate.add(const Duration(days: 1));
    final auth = FirebaseAuth.instance.currentUser;
    bool isReserving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F5F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4CFC4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Foto
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: DeviceImage(imageUrl: device.imageUrl),
                  ),
                ),
                const SizedBox(height: 16),

                // Titel
                Text(
                  device.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),

                // Beschrijving
                if (device.description.isNotEmpty)
                  Text(
                    device.description,
                    style: const TextStyle(
                      color: Color(0xFF6B6560),
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 12),

                // Prijs + categorie badges
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
                    const SizedBox(width: 10),
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

                // Locatie blok — geen API key nodig
                if (device.lat != 0 && device.lng != 0) ...[
                  const Text(
                    'Locatie',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0DBD1)),
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
                            Icons.location_on,
                            color: Color(0xFF2D6A4F),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.city.isNotEmpty
                                    ? device.city
                                    : 'Locatie beschikbaar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${device.lat.toStringAsFixed(4)}, '
                                '${device.lng.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  color: Color(0xFF9E9890),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // OpenStreetMap link knop
                        GestureDetector(
                          onTap: () {
                            final url =
                                'https://www.openstreetmap.org/?mlat=${device.lat}'
                                '&mlon=${device.lng}#map=15/${device.lat}/${device.lng}';
                            // open in browser
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9E0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Kaart',
                              style: TextStyle(
                                color: Color(0xFF2D6A4F),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Reserveer knop
                GestureDetector(
                  onTap: isReserving
                      ? null
                      : () async {
                          if (auth == null) return;
                          setModalState(() => isReserving = true);
                          try {
                            await service.makeReservation(
                              deviceId: device.id,
                              deviceTitle: device.title,
                              renterId: auth.uid,
                              start: startDate,
                              end: endDate,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reservering bevestigd!'),
                                  backgroundColor: Color(0xFF2D6A4F),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isReserving = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Fout: $e')),
                              );
                            }
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isReserving
                          ? const Color(0xFF9E9890)
                          : const Color(0xFF2D6A4F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: isReserving
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
