import 'package:flutter/material.dart';
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
    // Verwijder ook alle reserveringen voor dit toestel
    final reservations = await _db
        .collection('reservations')
        .where('deviceId', isEqualTo: id)
        .get();
    for (final doc in reservations.docs) {
      await doc.reference.delete();
    }
    await _db.collection('devices').doc(id).delete();
  }

  /// Haalt alle goedgekeurde/bevestigde reserveringen op voor een toestel
  Future<List<DateTimeRange>> getBlockedPeriods(String deviceId) async {
    final snap = await _db
        .collection('reservations')
        .where('deviceId', isEqualTo: deviceId)
        .where('status', whereIn: ['bevestigd', 'goedgekeurd'])
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      return DateTimeRange(start: start, end: end);
    }).toList();
  }

  /// Controleert of een periode overlapt met bestaande reserveringen
  bool _hasConflict(DateTimeRange requested, List<DateTimeRange> blocked) {
    for (final b in blocked) {
      // Overlap als: start voor einde geblokkeerde periode EN einde na start
      final overlaps =
          requested.start.isBefore(b.end.add(const Duration(days: 1))) &&
          requested.end.isAfter(b.start.subtract(const Duration(days: 1)));
      if (overlaps) return true;
    }
    return false;
  }

  Future<void> makeReservation({
    required String deviceId,
    required String deviceTitle,
    required String ownerId,
    required String renterId,
    required DateTime start,
    required DateTime end,
  }) async {
    // Conflict check VOOR opslaan
    final blocked = await getBlockedPeriods(deviceId);
    final requested = DateTimeRange(start: start, end: end);

    if (_hasConflict(requested, blocked)) {
      throw Exception('Deze periode is al gereserveerd. Kies andere datums.');
    }

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

  Future<void> cancelReservation(String reservationId) async {
    await _db.collection('reservations').doc(reservationId).update({
      'status': 'geannuleerd',
    });
  }

  Future<void> submitReview({
    required String deviceId,
    required String reviewerId,
    required String reviewerName,
    required double rating,
    required String comment,
  }) async {
    // Check of gebruiker al een review heeft geplaatst
    final existing = await _db
        .collection('reviews')
        .where('deviceId', isEqualTo: deviceId)
        .where('reviewerId', isEqualTo: reviewerId)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Je hebt dit toestel al beoordeeld.');
    }

    await _db.collection('reviews').add({
      'deviceId': deviceId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.now(),
    });

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
