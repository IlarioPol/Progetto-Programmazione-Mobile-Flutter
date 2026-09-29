import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/booking.dart';
import '../../data/models/review.dart';
import '../../data/models/service.dart';
import '../../data/models/app_user.dart';
import '../../data/models/availability.dart';

/// ViewModel for the Provider role.
class ProviderViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Service> services = [];
  List<Review> reviews = [];
  List<Booking> incomingBookings = [];
  double totalTurnover = 0.0;
  ProviderAvailability? availability;

  AppUser? _currentUser;

  StreamSubscription? _servicesSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _reviewsSub;
  StreamSubscription? _availabilitySub;

  ProviderViewModel() {
    _fetchCurrentUserAndData();
  }

  @override
  void dispose() {
    _servicesSub?.cancel();
    _bookingsSub?.cancel();
    _reviewsSub?.cancel();
    _availabilitySub?.cancel();
    super.dispose();
  }

  void _fetchCurrentUserAndData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
        fetchMyServices();
        _fetchMyAvailability();
      }
    } catch (_) {}
  }

  void fetchMyServices() {
    final providerId = _auth.currentUser?.uid;
    if (providerId == null) return;

    _servicesSub?.cancel();
    _servicesSub = _db
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .listen((snapshot) {
      services =
          snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
      notifyListeners();
      _fetchIncomingBookings();
      _fetchReviews(services.map((s) => s.id).toList());
    });
  }

  void _fetchIncomingBookings() {
    _bookingsSub?.cancel();
    _bookingsSub =
        _db.collection('bookings').snapshots().listen((snapshot) {
      final allBookings =
          snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      final myServiceIds = services.map((s) => s.id).toSet();
      incomingBookings =
          allBookings.where((b) => myServiceIds.contains(b.serviceId)).toList();
      _calculateStats();
      notifyListeners();
    });
  }

  void _fetchReviews(List<String> serviceIds) {
    if (serviceIds.isEmpty) return;
    _reviewsSub?.cancel();
    _reviewsSub =
        _db.collection('reviews').snapshots().listen((snapshot) {
      final allReviews =
          snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
      reviews = allReviews
          .where((r) => serviceIds.contains(r.serviceId))
          .toList();
      notifyListeners();
    });
  }

  void _fetchMyAvailability() {
    final providerId = _auth.currentUser?.uid;
    if (providerId == null) return;

    _availabilitySub?.cancel();
    _availabilitySub = _db
        .collection('availabilities')
        .doc(providerId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        availability = ProviderAvailability.fromFirestore(snapshot);
      } else {
        availability = ProviderAvailability.getDefault(providerId);
      }
      notifyListeners();
    });
  }

  Future<void> updateAvailability(ProviderAvailability newAvailability) async {
    final providerId = _auth.currentUser?.uid;
    if (providerId == null) return;

    // Optimistic UI update
    availability = newAvailability;
    notifyListeners();

    await _db
        .collection('availabilities')
        .doc(providerId)
        .set(newAvailability.toFirestore());
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'status': newStatus});
  }

  Future<void> addService(
    String name,
    String description,
    int duration,
    double price,
  ) async {
    final providerId = _auth.currentUser?.uid;
    if (providerId == null) return;
    final bId = _currentUser?.businessId ?? '';
    final serviceId = const Uuid().v4();

    final newService = Service(
      id: serviceId,
      name: name,
      description: description,
      durationMinutes: duration,
      price: price,
      providerId: providerId,
      businessId: bId,
    );
    await _db
        .collection('services')
        .doc(serviceId)
        .set(newService.toFirestore());
  }

  Future<void> updateService(
    String serviceId,
    String name,
    String description,
    int duration,
    double price,
  ) async {
    await _db.collection('services').doc(serviceId).update({
      'name': name,
      'description': description,
      'durationMinutes': duration,
      'price': price,
    });
  }

  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }

  void _calculateStats() {
    var total = 0.0;
    final completedBookings =
        incomingBookings.where((b) => b.status == 'Completed');
    for (final booking in completedBookings) {
      final service =
          services.where((s) => s.id == booking.serviceId).firstOrNull;
      if (service != null) {
        total += service.price;
      }
    }
    totalTurnover = total;
  }
}
