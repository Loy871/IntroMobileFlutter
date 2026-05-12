import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  LatLng _selected = const LatLng(51.2194, 4.4025);
  String _address = '';
  bool _searching = false;
  List<Map<String, dynamic>> _suggestions = [];

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _searching = true;
      _suggestions = [];
    });
    try {
      // Zoek eerst in België, dan Nederland, dan overal
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=6'
        '&accept-language=nl'
        '&addressdetails=1',
      );
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'BuurtLeenApp/1.0 contact@buurtleen.be',
          'Accept-Language': 'nl',
        },
      );

      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        setState(() {
          _suggestions = data.map((e) {
            final addr = e['address'] as Map<String, dynamic>? ?? {};
            // Bouw leesbaar Nederlands adres
            final parts = <String>[];
            if (addr['road'] != null) parts.add(addr['road']);
            if (addr['house_number'] != null) parts.add(addr['house_number']);
            final city =
                addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['municipality'] ??
                '';
            if (city.isNotEmpty) parts.add(city);
            final postcode = addr['postcode'] ?? '';
            if (postcode.isNotEmpty) parts.add(postcode);

            final displayShort = parts.isNotEmpty
                ? parts.join(' ')
                : e['display_name'];
            final country = addr['country'] ?? addr['country_code'] ?? '';

            return {
              'display': displayShort,
              'country': country,
              'full': e['display_name'],
              'lat': double.parse(e['lat']),
              'lng': double.parse(e['lon']),
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Zoekfout: $e')));
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&format=json&accept-language=nl&addressdetails=1',
      );
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'BuurtLeenApp/1.0', 'Accept-Language': 'nl'},
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final parts = <String>[];
        if (addr['road'] != null) parts.add(addr['road']);
        if (addr['house_number'] != null) parts.add(addr['house_number']);
        final city =
            addr['city'] ??
            addr['town'] ??
            addr['village'] ??
            addr['municipality'] ??
            '';
        if (city.isNotEmpty) parts.add(city);
        setState(
          () => _address = parts.isNotEmpty
              ? parts.join(', ')
              : data['display_name'],
        );
        _searchController.text = _address;
      }
    } catch (_) {
      setState(
        () => _address =
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
      );
    }
  }

  void _selectSuggestion(Map<String, dynamic> s) {
    final pos = LatLng(s['lat'], s['lng']);
    setState(() {
      _selected = pos;
      _address = s['display'];
      _suggestions = [];
      _searchController.text = _address;
    });
    _mapController.move(pos, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kies locatie',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                // Zoekbalk
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: 'Zoek straat, stad of postcode...',
                      hintStyle: const TextStyle(color: AppTheme.textLight),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.greenLight,
                      ),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.green,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppTheme.textLight,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _suggestions = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) {
                      if (v.length >= 2) _search(v);
                      if (v.isEmpty) setState(() => _suggestions = []);
                    },
                  ),
                ),

                // Suggesties dropdown
                if (_suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.border),
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.greenPale,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppTheme.green,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            s['display'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          subtitle: s['country'].isNotEmpty
                              ? Text(
                                  s['country'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textLight,
                                  ),
                                )
                              : null,
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Kaart
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selected,
                    initialZoom: 13,
                    onTap: (_, pos) async {
                      setState(() {
                        _selected = pos;
                        _suggestions = [];
                      });
                      await _reverseGeocode(pos);
                    },
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
                          point: _selected,
                          width: 48,
                          height: 48,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.green.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.home,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Hint overlay
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Zoek bovenaan of tik op de kaart',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bevestig paneel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_address.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.greenPale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _address,
                            style: const TextStyle(
                              color: AppTheme.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFE67F00),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Zoek een adres of tik op de kaart',
                          style: TextStyle(
                            color: Color(0xFFE67F00),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, {
                    'lat': _selected.latitude,
                    'lng': _selected.longitude,
                    'address': _address,
                  }),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _address.isNotEmpty
                          ? AppTheme.green
                          : AppTheme.textLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Locatie bevestigen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
}
