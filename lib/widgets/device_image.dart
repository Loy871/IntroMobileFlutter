import 'dart:convert';
import 'package:flutter/material.dart';

class DeviceImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? height;
  final double? width;

  const DeviceImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _placeholder();

    // Base64 afbeelding
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          height: height,
          width: width,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }

    // Normale URL
    return Image.network(
      imageUrl,
      fit: fit,
      height: height,
      width: width,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    height: height,
    width: width,
    color: const Color(0xFFEDE9E0),
    child: const Center(
      child: Icon(Icons.devices, size: 40, color: Color(0xFFB0A99E)),
    ),
  );
}
