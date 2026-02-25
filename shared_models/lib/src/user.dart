import 'collections.dart';
import 'utils.dart';

/// Model užívateľa – Firestore kolekcia [Collections.users].
class User {
  User({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.roles = const [],
    this.managedShopIds = const [],
    this.createdAt,
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final List<String> managedShopIds;
  final DateTime? createdAt;

  String get displayName => '$firstName $lastName'.trim();

  static User? fromMap(Map<String, dynamic>? data, {String? documentId}) {
    if (data == null) return null;
    final uid = documentId ?? data['uid'] as String? ?? data['id'] as String?;
    if (uid == null) return null;
    return User(
      uid: uid.toString(),
      email: (data['email'] as String?) ?? '',
      firstName: (data['firstName'] as String?) ?? '',
      lastName: (data['lastName'] as String?) ?? '',
      roles: _stringList(data['roles']),
      managedShopIds: _stringList(data['managedShopIds']),
      createdAt: MatGoUtils.parseDate(data['createdAt']),
    );
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'roles': roles,
        'managedShopIds': managedShopIds,
      };
}
