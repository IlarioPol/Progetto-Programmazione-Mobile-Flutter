import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a business/company in the EasyBook system.
class Business {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String managerId;
  final List<String> providerIds;
  final List<String> imageUrls;

  const Business({
    this.id = '',
    this.name = '',
    this.category = '',
    this.description = '',
    this.address = '',
    this.managerId = '',
    this.providerIds = const [],
    this.imageUrls = const [],
  });

  factory Business.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Business(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      address: data['address'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      providerIds: List<String>.from(data['providerIds'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  factory Business.fromMap(Map<String, dynamic> data) {
    return Business(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      address: data['address'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      providerIds: List<String>.from(data['providerIds'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'managerId': managerId,
      'providerIds': providerIds,
      'imageUrls': imageUrls,
    };
  }
}
