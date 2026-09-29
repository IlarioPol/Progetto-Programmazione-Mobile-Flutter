import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a client review for a service.
class Review {
  final String id;
  final String serviceId;
  final String serviceName;
  final String clientName;
  final int rating;
  final String comment;
  final String date;

  const Review({
    this.id = '',
    this.serviceId = '',
    this.serviceName = '',
    this.clientName = '',
    this.rating = 0,
    this.comment = '',
    this.date = '',
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Review.fromMap(data);
  }

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: data['id'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      date: data['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'clientName': clientName,
      'rating': rating,
      'comment': comment,
      'date': date,
    };
  }
}
