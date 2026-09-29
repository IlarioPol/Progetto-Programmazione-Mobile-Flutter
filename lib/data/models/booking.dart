import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a booking in the EasyBook system.
class Booking {
  final String id;
  final String serviceId;
  final String providerId;
  final String businessId;
  final String serviceName;
  final String clientId;
  final String date; // Formato "dd/MM/yyyy HH:mm"
  final String status; // Pending, Confirmed, Completed, Canceled, Rejected

  const Booking({
    this.id = '',
    this.serviceId = '',
    this.providerId = '',
    this.businessId = '',
    this.serviceName = '',
    this.clientId = '',
    this.date = '',
    this.status = 'Pending',
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Booking.fromMap(data);
  }

  factory Booking.fromMap(Map<String, dynamic> data) {
    return Booking(
      id: data['id'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      businessId: data['businessId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'serviceId': serviceId,
      'providerId': providerId,
      'businessId': businessId,
      'serviceName': serviceName,
      'clientId': clientId,
      'date': date,
      'status': status,
    };
  }
}
