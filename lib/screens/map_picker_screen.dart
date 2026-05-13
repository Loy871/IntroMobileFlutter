import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _searchController = TextEditingController();

  GoogleMapController? _controller;

  LatLng _selected = const LatLng(51.2194, 4.4025); // Antwerpen
  String _address = '';
  bool _searching = false;
  List<Map<String, dynamic>> _suggestions = [];

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  // 🔍 Search (Nominatim blijft hetzelfde)
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
          'User-Agent': 'BuurtLeenApp/1.0',
          'Accept-Language': 'nl',
        },
      ).timeout(const Duration(seconds: 6));


      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);

        setState(() {
          _suggestions = data.map((e) {
            final addr = e['address'] as Map<String, dynamic>? ?? {};

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

            final display = parts.isNotEmpty
                ? parts.join(' ')
                : e['display_name'];

            return {
              'display': display,
              'lat': double.parse(e['lat']),
              'lng': double.parse(e['lon']),
            };
          }).toList();
        });
      }
    } catch (_) {
      setState(() {
        _address = 'Locatie geselecteerd';
        _searchController.text = '';
      });
    }

    if (mounted) setState(() => _searching = false);
  }

  // 📍 Reverse geocode
  Future<void> _reverseGeocode(LatLng pos) async {
  setState(() {
    _address = 'Zoeken...';
  });

  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=${pos.latitude}&lon=${pos.longitude}'
      '&format=json'
      '&accept-language=nl'
      '&addressdetails=1',
    );

    final resp = await http.get(
      uri,
      headers: {
        'User-Agent': 'BuurtLeenApp (contact@buurtleen.be)',
        'Accept-Language': 'nl',
      },
    ).timeout(const Duration(seconds: 6));

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final addr = data['address'] ?? {};

      final road = addr['road'];
      final house = addr['house_number'];

      final city =
          addr['city'] ??
          addr['town'] ??
          addr['village'] ??
          addr['municipality'];

      final parts = <String>[];

      if (road != null) parts.add(road);
      if (house != null) parts.add(house);
      if (city != null) parts.add(city);

      final result = parts.isNotEmpty
          ? parts.join(', ')
          : (data['display_name'] ?? '');

      setState(() {
        _address = result;
        _searchController.text = result;
      });
    } else {
      _setFallback(pos);
    }
  } catch (_) {
    _setFallback(pos);
  }
}

void _setFallback(LatLng pos) {
  setState(() {
    _address =
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    _searchController.text = _address;
  });
}

  void _selectSuggestion(Map<String, dynamic> s) {
    final pos = LatLng(s['lat'], s['lng']);

    setState(() {
      _selected = pos;
      _address = s['display'];
      _suggestions = [];
      _searchController.text = _address;
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(pos, 15),
    );
  }

  void _confirm() {
    Navigator.pop(context, {
      'lat': _selected.latitude,
      'lng': _selected.longitude,
      'address': _address,
    });
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
          // 🔎 SEARCH
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    if (v.length >= 2) _search(v);
                    if (v.isEmpty) setState(() => _suggestions = []);
                  },
                  decoration: InputDecoration(
                    hintText: 'Zoek straat, stad of postcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          title: Text(s['display']),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 🗺️ GOOGLE MAP
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selected,
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selected,
                ),
              },
              onTap: (pos) async {
                setState(() {
                  _selected = pos;
                  _address = 'Laden...';
                  _suggestions = [];
                });

                await _reverseGeocode(pos);

                _controller?.animateCamera(
                  CameraUpdate.newLatLng(pos),
                );
              },
            ),
          ),


          if (_address.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _address,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tik op de kaart of zoek een locatie',
                style: TextStyle(fontSize: 13),
              ),
            ),

          const SizedBox(height: 8),
          // ✅ CONFIRM BUTTON
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Locatie bevestigen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}