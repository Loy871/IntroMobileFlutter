import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/star_rating.dart';

class ReviewDeviceScreen extends StatefulWidget {
  final String deviceId;
  final String deviceTitle;

  const ReviewDeviceScreen({
    super.key,
    required this.deviceId,
    required this.deviceTitle,
  });

  @override
  State<ReviewDeviceScreen> createState() => _ReviewDeviceScreenState();
}

class _ReviewDeviceScreenState extends State<ReviewDeviceScreen> {
  double _rating = 0;
  final _comment = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geef een score')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await DeviceService().submitReview(
        deviceId: widget.deviceId,
        reviewerId: user.uid,
        reviewerName: user.email?.split('@').first ?? 'Gebruiker',
        rating: _rating,
        comment: _comment.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beoordeling geplaatst!'),
          backgroundColor: AppTheme.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Beoordeel ${widget.deviceTitle}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            const Text(
              'Geef je ervaring',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 16),

            InteractiveStarRating(
              onChanged: (r) => setState(() => _rating = r),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Schrijf een review...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            AppButton(
              label: 'Plaatsen',
              loading: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}