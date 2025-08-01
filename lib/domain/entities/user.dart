class User {
  final String uid;
  final String email;

  User({required this.uid, required this.email});

  // Business logic methods
  bool get isAuthenticated => uid.isNotEmpty;

  User copyWith({String? uid, String? email}) {
    return User(uid: uid ?? this.uid, email: email ?? this.email);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'User{uid: $uid, email: $email}';
  }
}
