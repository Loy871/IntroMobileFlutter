import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  LatLng _selected = const LatLng(51.2194, 4.4025); // Antwerpen default
  String _address = '';
  bool _searching = false;
  List<Map<String, dynamic>> _suggestions = [];

  Future<void> _search(String query) async {
    if (query.length < 3) return;
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&countrycodes=be',
      );
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'BuurtLeenApp/1.0'},
      );
      final List data = json.decode(resp.body);
      setState(() {
        _suggestions = data
            .map(
              (e) => {
                'display': e['display_name'] as String,
                'lat': double.parse(e['lat']),
                'lng': double.parse(e['lon']),
              },
            )
            .toList();
      });
    } catch (_) {}
    setState(() => _searching = false);
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json',
      );
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'BuurtLeenApp/1.0'},
      );
      final data = json.decode(resp.body);
      final addr = data['address'] as Map<String, dynamic>;
      final parts = <String>[];
      if (addr['road'] != null) parts.add(addr['road']);
      if (addr['house_number'] != null) parts.add(addr['house_number']);
      if (addr['city'] ?? addr['town'] ?? addr['village'] != null)
        parts.add(addr['city'] ?? addr['town'] ?? addr['village'] ?? '');
      setState(() => _address = parts.join(', '));
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
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kies locatie',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Zoekbalk
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0DBD1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Zoek een adres...',
                      hintStyle: const TextStyle(color: Color(0xFFB0A99E)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF2D6A4F),
                      ),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2D6A4F),
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) => _search(v),
                  ),
                ),
                // Suggesties
                if (_suggestions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0DBD1)),
                    ),
                    child: Column(
                      children: _suggestions.map((s) {
                        final parts = s['display'].split(', ');
                        final title = parts.first;
                        final subtitle = parts.skip(1).take(2).join(', ');
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on,
                            color: Color(0xFF2D6A4F),
                            size: 18,
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9890),
                            ),
                          ),
                          onTap: () => _selectSuggestion(s),
                        );
                      }).toList(),
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
                      setState(() => _selected = pos);
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
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF2D6A4F),
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Hint
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Tik op de kaart om te selecteren',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B6560),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Geselecteerd adres + bevestigen
          Container(
            padding: const EdgeInsets.all(20),
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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2D6A4F),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _address,
                            style: const TextStyle(
                              color: Color(0xFF2D6A4F),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F),
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
