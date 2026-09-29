import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a service offered by a provider.
class Service {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final String providerId;
  final String businessId;

  const Service({
    this.id = '',
    this.name = '',
    this.description = '',
    this.durationMinutes = 0,
    this.price = 0.0,
    this.providerId = '',
    this.businessId = '',
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Service.fromMap(data);
  }

  factory Service.fromMap(Map<String, dynamic> data) {
    return Service(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      providerId: data['providerId'] as String? ?? '',
      businessId: data['businessId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'providerId': providerId,
      'businessId': businessId,
    };
  }
}
