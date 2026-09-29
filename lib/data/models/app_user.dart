import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Represents a user in the EasyBook system.
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? managerId;
  final String? businessId;

  const AppUser({
    this.id = '',
    this.name = '',
    this.email = '',
    this.role = UserRole.client,
    this.managerId,
    this.businessId,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'CLIENT'),
      managerId: data['managerId'] as String?,
      businessId: data['businessId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.firestoreName,
      if (managerId != null) 'managerId': managerId,
      if (businessId != null) 'businessId': businessId,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? managerId,
    String? businessId,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      managerId: managerId ?? this.managerId,
      businessId: businessId ?? this.businessId,
    );
  }
}
