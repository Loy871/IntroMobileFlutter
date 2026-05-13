import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import 'map_picker_screen.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});
  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _category = 'Tuin';
  Uint8List? _imageBytes;
  bool _loading = false;
  bool _available = true;
  double? _lat;
  double? _lng;
  String _address = '';
  final _service = DeviceService();

  final List<String> _categories = [
    'Tuin',
    'Keuken',
    'Schoonmaak',
    'Gereedschap',
    'Overig',
  ];

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 700,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.length > 800000) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto te groot, kies een kleinere')),
            );
          return;
        }
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fout: $e')));
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
        _address = result['address'] ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      _snack('Geef een naam in');
      return;
    }
    if (_price.text.trim().isEmpty) {
      _snack('Geef een prijs in');
      return;
    }
    if (_lat == null) {
      _snack('Kies een locatie op de kaart');
      return;
    }

    setState(() => _loading = true);
    try {
      String imageUrl = '';
      if (_imageBytes != null) {
        imageUrl = _service.imageToBase64(_imageBytes!);
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Niet ingelogd');

      // Stad extraheren uit adres
      final parts = _address.split(',');

      final city = parts.last.trim();

      await _service.addDevice(
        Device(
          id: '',
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category,
          imageUrl: imageUrl,
          pricePerDay:
              double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0,
          ownerId: user.uid,
          city: city,
          lat: _lat!,
          lng: _lng!,
          available: _available,
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toestel toegevoegd!'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Fout: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1A)),
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Toestel aanbieden',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        // Klein laad-indicatortje rechts in appbar
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            GestureDetector(
              onTap: _loading ? null : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD4CFC4),
                    width: 1.5,
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D6A4F),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Foto toevoegen',
                            style: TextStyle(
                              color: Color(0xFF6B6560),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'max ~700KB',
                            style: TextStyle(
                              color: Color(0xFF9E9890),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Naam toestel'),
            _field(_title, 'bv. Grasmaaier Bosch'),
            const SizedBox(height: 14),

            _label('Beschrijving'),
            TextField(
              controller: _description,
              maxLines: 3,
              enabled: !_loading,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: _deco('Vertel iets over het toestel...'),
            ),
            const SizedBox(height: 14),

            _label('Categorie'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DBD1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(12),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _category = v!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _label('Prijs per dag (€)'),
            _field(_price, 'bv. 5.00', type: TextInputType.number),
            const SizedBox(height: 14),

            // Beschikbaarheid toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DBD1)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Direct beschikbaar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                subtitle: Text(
                  _available ? 'Zichtbaar voor huurders' : 'Nog niet zichtbaar',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9890),
                  ),
                ),
                value: _available,
                activeColor: const Color(0xFF2D6A4F),
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _available = v),
              ),
            ),
            const SizedBox(height: 14),

            // Locatie picker
            _label('Locatie'),
            GestureDetector(
              onTap: _loading ? null : _pickLocation,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lat != null
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFFE0DBD1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _lat != null
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFEDE9E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.map_outlined,
                        color: _lat != null
                            ? const Color(0xFF2D6A4F)
                            : const Color(0xFF9E9890),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _address.isNotEmpty
                            ? _address
                            : 'Tik om locatie te kiezen op kaart',
                        style: TextStyle(
                          color: _lat != null
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFB0A99E),
                          fontSize: 13,
                          fontWeight: _lat != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFFB0A99E),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _loading
                      ? const Color(0xFF9E9890)
                      : const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Text(
                        'Toestel toevoegen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: c,
    keyboardType: type,
    enabled: !_loading,
    style: const TextStyle(color: Color(0xFF1A1A1A)),
    decoration: _deco(hint),
  );

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB0A99E)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0DBD1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0DBD1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 2),
    ),
  );
}
