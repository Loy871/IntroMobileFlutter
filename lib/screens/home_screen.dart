import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';
import '../widgets/device_image.dart';
import '../widgets/star_rating.dart';
import 'add_device_screen.dart';
import 'device_detail_screen.dart';
import 'reservations_screen.dart';
import 'owner_dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _deviceService = DeviceService();
  String _selectedCategory = 'Alles';
  int _tabIndex = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();

  double? _filterLat;
  double? _filterLng;
  double _radiusKm = 10; // default 10km

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Alles', 'icon': Icons.apps_rounded},
    {'label': 'Tuin', 'icon': Icons.grass_rounded},
    {'label': 'Keuken', 'icon': Icons.blender_rounded},
    {'label': 'Schoonmaak', 'icon': Icons.cleaning_services_rounded},
    {'label': 'Gereedschap', 'icon': Icons.build_rounded},
    {'label': 'Overig', 'icon': Icons.category_rounded},
  ];


  Future<void> _setMyLocation() async {
    final position = await Geolocator.getCurrentPosition();

    setState(() {
      _filterLat = position.latitude;
      _filterLng = position.longitude;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildBrowse(),
          const ReservationsScreen(),
          const OwnerDashboardScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Ontdekken',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Huurder',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Verhuurder',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profiel',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
              ),
              backgroundColor: AppTheme.green,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Aanbieden',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }


  Widget _buildBrowse() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.bg,
          floating: true,
          snap: true,
          elevation: 0,
          titleSpacing: 16,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'BuurtLeen',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _tabIndex = 3),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.textMid,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Column(
              children: [
                // Zoekbalk
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Zoek een toestel...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.greenLight,
                          size: 20,
                        ),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.textLight,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                // Categorie chips
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final sel = _selectedCategory == cat['label'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat['label']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.green : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? AppTheme.green : AppTheme.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  cat['icon'] as IconData,
                                  size: 13,
                                  color: sel ? Colors.white : AppTheme.textMid,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cat['label'],
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : AppTheme.textMid,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
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
              ],
            ),
          ),
        ),
        StreamBuilder<List<Device>>(
          stream: _deviceService.getDevices(
            category: _selectedCategory,
            search: _search,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.green),
                ),
              );
            }
            final devices = List<Device>.from(snap.data ?? []);

            devices.sort((a, b) {
              final aTime = a.createdAt;
              final bTime = b.createdAt;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });
            if (devices.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.greenPale,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppTheme.greenLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Niets gevonden',
                        style: TextStyle(
                          color: AppTheme.textMid,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Probeer een andere zoekterm of categorie',
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) =>
                      _DeviceCard(device: devices[i], service: _deviceService),
                  childCount: devices.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceDetailScreen(device: device, service: service),
        ),
      ),
      child: Container(
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: DeviceImage(
                      imageUrl: device.imageUrl,
                      width: double.infinity,
                    ),
                  ),
                  // Categorie badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        device.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMid,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (device.avgRating > 0)
                    StarRating(
                      rating: device.avgRating,
                      count: device.reviewCount,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.greenPale,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '€${device.pricePerDay}/dag',
                          style: const TextStyle(
                            color: AppTheme.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (device.city.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppTheme.textLight,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              device.city,
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
}
