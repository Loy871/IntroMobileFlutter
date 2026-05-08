import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

class EditDeviceScreen extends StatefulWidget {
  final Device device;
  const EditDeviceScreen({super.key, required this.device});
  @override
  State<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _price;
  late String _category;
  late bool _available;
  bool _loading = false;
  final _service = DeviceService();

  final List<String> _categories = [
    'Tuin',
    'Keuken',
    'Schoonmaak',
    'Gereedschap',
    'Overig',
  ];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.device.title);
    _description = TextEditingController(text: widget.device.description);
    _price = TextEditingController(text: widget.device.pricePerDay.toString());
    _category = widget.device.category;
    _available = widget.device.available;
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _service.updateDevice(widget.device.id, {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'category': _category,
        'pricePerDay': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
        'available': _available,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wijzigingen opgeslagen'),
            backgroundColor: AppTheme.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fout: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Toestel bewerken'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Naam'),
            TextField(
              controller: _title,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: AppTheme.inputDecoration('Naam toestel'),
            ),
            const SizedBox(height: 14),
            _label('Beschrijving'),
            TextField(
              controller: _description,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: AppTheme.inputDecoration('Beschrijving'),
            ),
            const SizedBox(height: 14),
            _label('Categorie'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: AppTheme.textDark),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label('Prijs per dag (€)'),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: AppTheme.inputDecoration('bv. 5.00'),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Beschikbaar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                value: _available,
                activeColor: AppTheme.green,
                onChanged: (v) => setState(() => _available = v),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Wijzigingen opslaan',
              loading: _loading,
              onTap: _save,
              icon: Icons.save_outlined,
            ),
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
        color: AppTheme.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );
}
