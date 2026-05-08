import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/device.dart';
import '../services/device_service.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});
  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  String _category = 'Tuin';
  Uint8List? _imageBytes;
  bool _loading = false;
  String _loadingText = 'Bezig...';
  final _service = DeviceService();

  final List<String> _categories = [
    'Tuin',
    'Keuken',
    'Schoonmaak',
    'Gereedschap',
    'Overig',
  ];

  static const Map<String, List<double>> _cityCoords = {
    'antwerpen': [51.2194, 4.4025],
    'gent': [51.0543, 3.7174],
    'brussel': [50.8503, 4.3517],
    'brugge': [51.2093, 3.2247],
    'leuven': [50.8798, 4.7005],
    'mechelen': [51.0259, 4.4776],
    'hasselt': [50.9307, 5.3378],
    'kortrijk': [50.8277, 3.2647],
    'namen': [50.4669, 4.8674],
    'luik': [50.6326, 5.5797],
  };

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 40, // Laag houden want Firestore doc max 1MB
        maxWidth: 600,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        // Waarschuwing als foto te groot is
        if (bytes.length > 700000) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto is te groot, kies een kleinere foto'),
                backgroundColor: Colors.orange,
              ),
            );
          return;
        }
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kon foto niet laden: $e')));
    }
  }

  List<double> _getCoordsFromCity(String city) {
    final key = city.toLowerCase().trim();
    for (final entry in _cityCoords.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return [50.5039, 4.4699];
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty ||
        _price.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul naam, prijs en stad in')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _loadingText = 'Gegevens opslaan...';
    });

    try {
      String imageUrl = '';
      if (_imageBytes != null) {
        setState(() => _loadingText = 'Foto verwerken...');
        imageUrl = _service.imageToBase64(_imageBytes!);
      }

      final coords = _getCoordsFromCity(_city.text);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Niet ingelogd');

      setState(() => _loadingText = 'Opslaan in database...');

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
          city: _city.text.trim(),
          lat: coords[0],
          lng: coords[1],
          available: true,
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
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF7F5F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F5F0),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1A1A1A),
              ),
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto picker
                GestureDetector(
                  onTap: _loading ? null : _pickImage,
                  child: Container(
                    height: 200,
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
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D6A4F),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tik om foto te kiezen',
                                style: TextStyle(
                                  color: Color(0xFF6B6560),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Kleine foto aanbevolen (< 700KB)',
                                style: TextStyle(
                                  color: Color(0xFF9E9890),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                _label('Naam toestel'),
                _field(_title, 'bv. Grasmaaier Bosch'),
                const SizedBox(height: 16),
                _label('Beschrijving'),
                TextField(
                  controller: _description,
                  maxLines: 3,
                  enabled: !_loading,
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  decoration: _inputDecoration(
                    'Vertel iets over het toestel...',
                  ),
                ),
                const SizedBox(height: 16),
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
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                ),
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
                const SizedBox(height: 16),
                _label('Prijs per dag (€)'),
                _field(_price, 'bv. 5.00', type: TextInputType.number),
                const SizedBox(height: 16),
                _label('Stad / gemeente'),
                _field(_city, 'bv. Antwerpen'),
                const SizedBox(height: 32),
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
                    child: const Text(
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Loading overlay
        if (_loading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF2D6A4F)),
                    const SizedBox(height: 16),
                    Text(
                      _loadingText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
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
    decoration: _inputDecoration(hint),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
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
