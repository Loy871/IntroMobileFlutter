import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/device.dart';

class DeviceService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Device>> getDevices({String? category, String? search}) {
    Query query = _db.collection('devices').where('available', isEqualTo: true);
    if (category != null && category != 'Alles') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snap) {
      var devices = snap.docs
          .map((d) => Device.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        devices = devices
            .where(
              (d) =>
                  d.title.toLowerCase().contains(q) ||
                  d.description.toLowerCase().contains(q) ||
                  d.category.toLowerCase().contains(q) ||
                  d.city.toLowerCase().contains(q),
            )
            .toList();
      }
      return devices;
    });
  }

  String imageToBase64(Uint8List bytes) =>
      'data:image/jpeg;base64,${base64Encode(bytes)}';

  Future<void> addDevice(Device device) async {
    await _db.collection('devices').add(device.toMap());
  }

  Future<void> updateDevice(String id, Map<String, dynamic> data) async {
    await _db.collection('devices').doc(id).update(data);
  }

  Future<void> deleteDevice(String id) async {
    await _db.collection('devices').doc(id).delete();
  }

  Future<void> makeReservation({
    required String deviceId,
    required String deviceTitle,
    required String ownerId,
    required String renterId,
    required DateTime start,
    required DateTime end,
  }) async {
    await _db.collection('reservations').add({
      'deviceId': deviceId,
      'deviceTitle': deviceTitle,
      'ownerId': ownerId,
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
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> submitReview({
    required String deviceId,
    required String reviewerId,
    required String reviewerName,
    required double rating,
    required String comment,
  }) async {
    await _db.collection('reviews').add({
      'deviceId': deviceId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.now(),
    });
    // Update gemiddelde rating op device
    final reviews = await _db
        .collection('reviews')
        .where('deviceId', isEqualTo: deviceId)
        .get();
    final ratings = reviews.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .toList();
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    await _db.collection('devices').doc(deviceId).update({
      'avgRating': avg,
      'reviewCount': ratings.length,
    });
  }

  Stream<List<Map<String, dynamic>>> getReviews(String deviceId) {
    return _db
        .collection('reviews')
        .where('deviceId', isEqualTo: deviceId)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}
