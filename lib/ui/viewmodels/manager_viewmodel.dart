import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/review.dart';
import '../../data/models/service.dart';

/// Statistics for a single provider.
class ProviderStat {
  final String name;
  final double turnover;
  final double rating;

  const ProviderStat({
    required this.name,
    required this.turnover,
    required this.rating,
  });
}

/// Trend data for a service.
class ServiceTrend {
  final String name;
  final int count;

  const ServiceTrend({required this.name, required this.count});
}

/// ViewModel for the Manager role.
class ManagerViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? inviteStatus;
  List<AppUser> myProviders = [];

  double totalTurnover = 0.0;
  double monthlyTurnover = 0.0;
  List<ProviderStat> providerStats = [];
  List<ServiceTrend> serviceTrends = [];
  double averageRating = 0.0;

  StreamSubscription? _providersSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _reviewsSub;

  @override
  void dispose() {
    _providersSub?.cancel();
    _bookingsSub?.cancel();
    _reviewsSub?.cancel();
    super.dispose();
  }

  Future<void> inviteProvider(
    String email,
    String? businessId,
    String? businessName,
  ) async {
    if (businessId == null) {
      inviteStatus = 'Errore: Azienda non configurata';
      notifyListeners();
      return;
    }

    final managerId = _auth.currentUser?.uid;
    if (managerId == null) return;

    final invitation = {
      'email': email,
      'managerId': managerId,
      'businessId': businessId,
      'businessName': businessName ?? 'Azienda',
      'status': 'pending',
    };

    try {
      await _db.collection('invitations').doc(email).set(invitation);
      inviteStatus = 'Invito inviato a $email';
    } catch (_) {
      inviteStatus = "Errore nell'invio dell'invito";
    }
    notifyListeners();
  }

  void fetchMyProviders(String? businessId) {
    if (businessId == null) return;

    _providersSub?.cancel();
    _providersSub = _db
        .collection('users')
        .where('businessId', isEqualTo: businessId)
        .where('role', isEqualTo: 'PROVIDER')
        .snapshots()
        .listen((result) {
      myProviders =
          result.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
      notifyListeners();
      _fetchStatistics(businessId);
    });
  }

  void _fetchStatistics(String businessId) {
    _bookingsSub?.cancel();
    _bookingsSub = _db
        .collection('bookings')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .listen((bookingsSnapshot) {
      final bookings = bookingsSnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _db
          .collection('services')
          .where('businessId', isEqualTo: businessId)
          .get()
          .then((servicesSnapshot) {
        final services = servicesSnapshot.docs
            .map((doc) => Service.fromFirestore(doc))
            .toList();

        final serviceIds = services.map((s) => s.id).toList();
        if (serviceIds.isNotEmpty) {
          _reviewsSub?.cancel();
          _reviewsSub = _db
              .collection('reviews')
              .where('serviceId', whereIn: serviceIds)
              .snapshots()
              .listen((reviewsSnapshot) {
            final reviews = reviewsSnapshot.docs
                .map((doc) => Review.fromFirestore(doc))
                .toList();
            _calculateStats(bookings, services, reviews);
          });
        } else {
          _calculateStats(bookings, services, []);
        }
      });
    });
  }

  void _calculateStats(
    List<Booking> bookings,
    List<Service> services,
    List<Review> reviews,
  ) {
    final completedBookings =
        bookings.where((b) => b.status == 'Completed').toList();

    // 1. Turnover
    var total = 0.0;
    var monthly = 0.0;
    final currentMonth = DateFormat('MM/yyyy').format(DateTime.now());

    for (final booking in completedBookings) {
      final service =
          services.where((s) => s.id == booking.serviceId).firstOrNull;
      final price = service?.price ?? 0.0;
      total += price;
      if (booking.date.contains(currentMonth)) {
        monthly += price;
      }
    }
    totalTurnover = total;
    monthlyTurnover = monthly;

    // 2. Provider Stats
    providerStats = myProviders.map((provider) {
      final pBookings =
          completedBookings.where((b) => b.providerId == provider.id).toList();
      final pTurnover = pBookings.fold<double>(0.0, (acc, b) {
        final svc = services.where((s) => s.id == b.serviceId).firstOrNull;
        return acc + (svc?.price ?? 0.0);
      });

      final pServiceIds = services
          .where((s) => s.providerId == provider.id)
          .map((s) => s.id)
          .toSet();
      final pReviews =
          reviews.where((r) => pServiceIds.contains(r.serviceId)).toList();
      final pRating = pReviews.isNotEmpty
          ? pReviews.map((r) => r.rating).reduce((a, b) => a + b) /
              pReviews.length
          : 0.0;

      return ProviderStat(
        name: provider.name,
        turnover: pTurnover,
        rating: pRating,
      );
    }).toList();

    // 3. Service Trends
    final trendMap = <String, int>{};
    for (final booking in bookings) {
      trendMap[booking.serviceName] =
          (trendMap[booking.serviceName] ?? 0) + 1;
    }
    serviceTrends = trendMap.entries
        .map((e) => ServiceTrend(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    if (serviceTrends.length > 5) {
      serviceTrends = serviceTrends.sublist(0, 5);
    }

    // 4. Team Rating
    averageRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length
        : 0.0;

    notifyListeners();
  }
}
