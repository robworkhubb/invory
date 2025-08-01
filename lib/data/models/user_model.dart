import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({required super.uid, required super.email});

  factory UserModel.fromEntity(User user) {
    return UserModel(uid: user.uid, email: user.email);
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(uid: map['uid'] ?? '', email: map['email'] ?? '');
  }
}
