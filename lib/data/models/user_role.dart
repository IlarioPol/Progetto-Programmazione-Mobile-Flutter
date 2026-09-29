/// Enum representing the possible user roles in the EasyBook system.
enum UserRole {
  client,
  provider,
  manager;

  /// Returns the Firestore string representation of this role.
  String get firestoreName => name.toUpperCase();

  /// Creates a [UserRole] from its Firestore string representation.
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.client,
    );
  }

  /// Returns the Italian display name for this role.
  String get displayName {
    switch (this) {
      case UserRole.client:
        return 'Cliente';
      case UserRole.provider:
        return 'Emettitore Servizi (Provider)';
      case UserRole.manager:
        return 'Responsabile (Manager)';
    }
  }
}
