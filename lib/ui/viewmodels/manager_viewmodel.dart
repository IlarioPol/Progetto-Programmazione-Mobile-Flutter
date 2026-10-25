import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/business.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? inviteStatus;
  List<AppUser> myProviders = [];

  double totalTurnover = 0.0;
  double monthlyTurnover = 0.0;
  List<ProviderStat> providerStats = [];
  List<ServiceTrend> serviceTrends = [];
  double averageRating = 0.0;

  bool isUploading = false;

  List<Booking> _currentBookings = [];
  List<Service> _currentServices = [];
  List<Review> _currentReviews = [];

  Business? currentBusiness;

  StreamSubscription? _providersSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _servicesSub;
  StreamSubscription? _reviewsSub;
  StreamSubscription? _businessSub;

  @override
  void dispose() {
    _providersSub?.cancel();
    _bookingsSub?.cancel();
    _servicesSub?.cancel();
    _reviewsSub?.cancel();
    _businessSub?.cancel();
    super.dispose();
  }

  void listenToBusiness(String? businessId) {
    if (businessId == null || businessId.isEmpty) return;
    _businessSub?.cancel();
    _businessSub = _db
        .collection('businesses')
        .doc(businessId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        currentBusiness = Business.fromFirestore(doc);
        notifyListeners();
      }
    });
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

      final providerIds = myProviders.map((p) => p.id).toList();
      syncBusinessDataRetroactively(businessId, providerIds);
      _startRealTimeStats(businessId, providerIds);
    });
  }

  Future<void> syncBusinessDataRetroactively(
    String businessId,
    List<String> providerIds,
  ) async {
    if (providerIds.isEmpty) return;

    try {
      // 1. Sincronizziamo i servizi dei provider
      final servicesSnap = await _db
          .collection('services')
          .where('providerId', whereIn: providerIds)
          .get();
      final batch1 = _db.batch();
      var needsCommit1 = false;
      for (final doc in servicesSnap.docs) {
        final bId = doc.data()['businessId'] as String?;
        if (bId == null || bId.isEmpty) {
          batch1.update(doc.reference, {'businessId': businessId});
          needsCommit1 = true;
        }
      }
      if (needsCommit1) await batch1.commit();

      // 2. Sincronizziamo le prenotazioni dei provider
      final bookingsSnap = await _db
          .collection('bookings')
          .where('providerId', whereIn: providerIds)
          .get();
      final batch2 = _db.batch();
      var needsCommit2 = false;
      for (final doc in bookingsSnap.docs) {
        final bId = doc.data()['businessId'] as String?;
        if (bId == null || bId.isEmpty) {
          batch2.update(doc.reference, {'businessId': businessId});
          needsCommit2 = true;
        }
      }
      if (needsCommit2) await batch2.commit();
    } catch (_) {}
  }

  void _startRealTimeStats(String businessId, List<String> providerIds) {
    _bookingsSub?.cancel();
    _servicesSub?.cancel();
    _reviewsSub?.cancel();

    if (providerIds.isEmpty) {
      _currentBookings = [];
      _currentServices = [];
      _currentReviews = [];
      _calculateStats();
      return;
    }

    // Ascolto prenotazioni
    _bookingsSub = _db
        .collection('bookings')
        .where('providerId', whereIn: providerIds)
        .snapshots()
        .listen((snapshot) {
      _currentBookings =
          snapshot.docs.map((d) => Booking.fromFirestore(d)).toList();
      _calculateStats();
    });

    // Ascolto servizi e recensioni
    _servicesSub = _db
        .collection('services')
        .where('providerId', whereIn: providerIds)
        .snapshots()
        .listen((snapshot) {
      _currentServices =
          snapshot.docs.map((d) => Service.fromFirestore(d)).toList();

      final serviceIds = _currentServices.map((s) => s.id).toList();
      if (serviceIds.isNotEmpty) {
        _reviewsSub?.cancel();
        _reviewsSub = _db
            .collection('reviews')
            .where('serviceId', whereIn: serviceIds)
            .snapshots()
            .listen((rSnapshot) {
          _currentReviews =
              rSnapshot.docs.map((d) => Review.fromFirestore(d)).toList();
          _calculateStats();
        });
      }
      _calculateStats();
    });
  }

  void _calculateStats() {
    final completedBookings =
        _currentBookings.where((b) => b.status == 'Completed').toList();

    // 1. Turnover
    var total = 0.0;
    var monthly = 0.0;
    final currentMonth = DateFormat('MM/yyyy').format(DateTime.now());

    for (final booking in completedBookings) {
      final service = _currentServices
          .where((s) => s.id == booking.serviceId)
          .firstOrNull;
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
      final pBookings = completedBookings
          .where((b) => b.providerId == provider.id)
          .toList();
      final pTurnover = pBookings.fold<double>(0.0, (acc, b) {
        final svc =
            _currentServices.where((s) => s.id == b.serviceId).firstOrNull;
        return acc + (svc?.price ?? 0.0);
      });

      final pServiceIds = _currentServices
          .where((s) => s.providerId == provider.id)
          .map((s) => s.id)
          .toSet();
      final pReviews = _currentReviews
          .where((r) => pServiceIds.contains(r.serviceId))
          .toList();
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
    for (final booking in _currentBookings) {
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
    averageRating = _currentReviews.isNotEmpty
        ? _currentReviews.map((r) => r.rating).reduce((a, b) => a + b) /
            _currentReviews.length
        : 0.0;

    notifyListeners();
  }

  Future<String?> uploadBusinessImage(String businessId, XFile imageFile) async {
    isUploading = true;
    notifyListeners();
    try {
      final imageId = const Uuid().v4();
      final extension = imageFile.name.contains('.')
          ? imageFile.name.split('.').last.toLowerCase()
          : 'jpg';
      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final storageRef = _storage
          .ref()
          .child('business_images/$businessId/$imageId.$extension');

      final metadata = SettableMetadata(contentType: contentType);

      final TaskSnapshot uploadTask;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = await storageRef.putData(bytes, metadata);
      } else {
        uploadTask = await storageRef.putFile(File(imageFile.path), metadata);
      }

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Atomic update with arrayUnion (creates array if missing)
      await _db.collection('businesses').doc(businessId).set({
        'imageUrls': FieldValue.arrayUnion([downloadUrl]),
      }, SetOptions(merge: true));

      // Immediate local state update for instant UI feedback
      if (currentBusiness != null && currentBusiness!.id == businessId) {
        final updatedUrls = List<String>.from(currentBusiness!.imageUrls)
          ..add(downloadUrl);
        currentBusiness = Business(
          id: currentBusiness!.id,
          name: currentBusiness!.name,
          category: currentBusiness!.category,
          description: currentBusiness!.description,
          address: currentBusiness!.address,
          managerId: currentBusiness!.managerId,
          providerIds: currentBusiness!.providerIds,
          imageUrls: updatedUrls,
        );
        notifyListeners();
      }

      return null;
    } on FirebaseException catch (e, stack) {
      debugPrint('Firebase error in uploadBusinessImage: ${e.code} - ${e.message}\n$stack');
      return e.message ?? e.code;
    } catch (e, stack) {
      debugPrint('General error in uploadBusinessImage: $e\n$stack');
      return e.toString();
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<String?> updateBusinessInfo(
    String businessId,
    String description,
    String address,
  ) async {
    try {
      await _db.collection('businesses').doc(businessId).set({
        'description': description,
        'address': address,
      }, SetOptions(merge: true));

      if (currentBusiness != null && currentBusiness!.id == businessId) {
        currentBusiness = Business(
          id: currentBusiness!.id,
          name: currentBusiness!.name,
          category: currentBusiness!.category,
          description: description,
          address: address,
          managerId: currentBusiness!.managerId,
          providerIds: currentBusiness!.providerIds,
          imageUrls: currentBusiness!.imageUrls,
        );
        notifyListeners();
      }
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteImage(String businessId, String imageUrl) async {
    try {
      await _db.collection('businesses').doc(businessId).update({
        'imageUrls': FieldValue.arrayRemove([imageUrl]),
      });

      if (currentBusiness != null && currentBusiness!.id == businessId) {
        final updatedUrls = List<String>.from(currentBusiness!.imageUrls)
          ..remove(imageUrl);
        currentBusiness = Business(
          id: currentBusiness!.id,
          name: currentBusiness!.name,
          category: currentBusiness!.category,
          description: currentBusiness!.description,
          address: currentBusiness!.address,
          managerId: currentBusiness!.managerId,
          providerIds: currentBusiness!.providerIds,
          imageUrls: updatedUrls,
        );
        notifyListeners();
      }

      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (e) {
        debugPrint('Warning deleting image from storage: $e');
      }

      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }
}
