import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device.dart';
import 'dart:convert';

class DeviceService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Device>> getDevices({String? category}) {
    Query query = _db.collection('devices');
    if (category != null && category != 'Alles') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => Device.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  // Sla foto op als base64 string in Firestore — geen Storage nodig
  String imageToBase64(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> addDevice(Device device) async {
    await _db.collection('devices').add(device.toMap());
  }

  Future<void> makeReservation({
    required String deviceId,
    required String deviceTitle,
    required String renterId,
    required DateTime start,
    required DateTime end,
  }) async {
    await _db.collection('reservations').add({
      'deviceId': deviceId,
      'deviceTitle': deviceTitle,
      'renterId': renterId,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'status': 'bevestigd',
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> getMyReservations(String userId) {
    return _db
        .collection('reservations')
        .where('renterId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }
}
