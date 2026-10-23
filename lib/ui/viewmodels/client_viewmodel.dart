import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/booking.dart';
import '../../data/models/business.dart';
import '../../data/models/review.dart';
import '../../data/models/service.dart';
import '../../data/models/availability.dart';
import '../../data/models/app_user.dart';

/// ViewModel for the Client role.
class ClientViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Service> _allServices = [];
  List<Business> _allBusinesses = [];

  List<Business> get allBusinesses => _allBusinesses;
  List<Service> get allServices => _allServices;

  List<Service> getServicesForBusiness(String businessId) {
    return _allServices.where((s) => s.businessId == businessId).toList();
  }

  List<Service> availableServices = [];
  List<Business> availableBusinesses = [];

  List<Booking> myBookings = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = 'Tutte';
  String get selectedCategory => _selectedCategory;

  ProviderAvailability? selectedProviderAvailability;
  List<String> availableSlots = [];

  StreamSubscription? _businessesSub;
  StreamSubscription? _servicesSub;
  StreamSubscription? _bookingsSub;

  ClientViewModel() {
    _fetchAllBusinesses();
    _fetchAllServices();
    _fetchMyBookings();
  }

  @override
  void dispose() {
    _businessesSub?.cancel();
    _servicesSub?.cancel();
    _bookingsSub?.cancel();
    super.dispose();
  }

  void _fetchAllBusinesses() {
    _businessesSub = _db.collection('businesses').snapshots().listen((snapshot) {
      _allBusinesses =
          snapshot.docs.map((doc) => Business.fromFirestore(doc)).toList();
      _applyFilters();
    });
  }

  void _fetchAllServices() {
    _servicesSub = _db.collection('services').snapshots().listen((snapshot) {
      _allServices =
          snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
      _applyFilters();
    });
  }

  void onSearchQueryChange(String newQuery) {
    _searchQuery = newQuery;
    _applyFilters();
  }

  void onCategorySelected(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();
    final cat = _selectedCategory.trim().toLowerCase();

    availableBusinesses = _allBusinesses.where((business) {
      final matchesQuery = query.isEmpty ||
          business.name.toLowerCase().contains(query) ||
          business.description.toLowerCase().contains(query) ||
          business.category.toLowerCase().contains(query);
      final matchesCat =
          cat == 'tutte' || business.category.trim().toLowerCase() == cat;
      return matchesQuery && matchesCat;
    }).toList();

    availableServices = _allServices.where((service) {
      final business =
          _allBusinesses.where((b) => b.id == service.businessId).firstOrNull;
      final matchesCat = cat == 'tutte' ||
          (business != null &&
              business.category.trim().toLowerCase() == cat);
      final matchesQuery = query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.description.toLowerCase().contains(query) ||
          (business != null &&
              business.name.toLowerCase().contains(query));
      return matchesCat && matchesQuery;
    }).toList();

    notifyListeners();
  }

  void _fetchMyBookings() {
    final clientId = _auth.currentUser?.uid;
    if (clientId == null) return;
    _bookingsSub = _db
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .listen((snapshot) {
      myBookings =
          snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  Future<void> fetchProviderAvailability(String providerId) async {
    try {
      final doc =
          await _db.collection('availabilities').doc(providerId).get();
      if (doc.exists) {
        selectedProviderAvailability =
            ProviderAvailability.fromFirestore(doc);
      } else {
        selectedProviderAvailability = null;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> generateSlots(Service service, String date) async {
    availableSlots = [];
    notifyListeners();

    final availability = selectedProviderAvailability;
    if (availability == null) return;

    final dateFormat = DateFormat('dd/MM/yyyy');
    DateTime parsedDate;
    try {
      parsedDate = dateFormat.parse(date);
    } catch (_) {
      return;
    }

    // Convert Dart weekday (Mon=1, Sun=7) to our format (same)
    final dayOfWeek = parsedDate.weekday;

    final dayAvail = availability.weeklyAvailability
        .where((d) => d.dayOfWeek == dayOfWeek)
        .firstOrNull;
    if (dayAvail == null || !dayAvail.workDay) return;

    // Fetch all bookings for this provider
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('providerId', isEqualTo: service.providerId)
          .get();

      final existingBookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .where((b) =>
              b.date.startsWith(date) &&
              b.status != 'Canceled' &&
              b.status != 'Rejected')
          .toList();

      final slots = <String>[];
      final timeFormat = DateFormat('HH:mm');
      final now = DateTime.now();
      final isToday = dateFormat.format(now) == date;

      for (final range in dayAvail.timeRanges) {
        final startParts = range.startTime.split(':');
        final endParts = range.endTime.split(':');

        var slotTime = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );
        final endTime = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        while (slotTime
            .add(Duration(minutes: service.durationMinutes))
            .compareTo(endTime) <=
            0) {
          if (isToday && slotTime.isBefore(now)) {
            slotTime = slotTime.add(const Duration(minutes: 30));
            continue;
          }

          final slotTimeStr = timeFormat.format(slotTime);
          final slotDateTime = '$date $slotTimeStr';

          final isOccupied =
              existingBookings.any((b) => b.date == slotDateTime);
          if (!isOccupied) {
            slots.add(slotTimeStr);
          }
          slotTime = slotTime.add(const Duration(minutes: 30));
        }
      }

      availableSlots = slots;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> bookService(Service service, String date) async {
    final clientId = _auth.currentUser?.uid;
    if (clientId == null) return;

    final bookingId = const Uuid().v4();
    final newBooking = Booking(
      id: bookingId,
      serviceId: service.id,
      providerId: service.providerId,
      businessId: service.businessId,
      serviceName: service.name,
      clientId: clientId,
      date: date,
      status: 'Pending',
    );
    await _db
        .collection('bookings')
        .doc(bookingId)
        .set(newBooking.toFirestore());
  }

  Future<void> cancelBooking(String bookingId) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'Canceled'});
  }

  Future<void> addReview(
    String serviceId,
    String serviceName,
    int rating,
    String comment,
  ) async {
    final clientName = _auth.currentUser?.displayName ?? 'Cliente';
    final reviewId = const Uuid().v4();

    final newReview = Review(
      id: reviewId,
      serviceId: serviceId,
      serviceName: serviceName,
      clientName: clientName,
      rating: rating,
      comment: comment,
      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    await _db
        .collection('reviews')
        .doc(reviewId)
        .set(newReview.toFirestore());
  }

  Future<List<AppUser>> fetchTeamMembers(String businessId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('businessId', isEqualTo: businessId)
          .get();
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (_) {
      return [];
    }
  }
}
