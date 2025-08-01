import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../datasources/firebaseauth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<User?> login(String email, String password) async {
    try {
      final firebaseUser = await _authService.loginWithEmailPassword(
        email,
        password,
      );
      if (firebaseUser != null) {
        return User(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  User? getCurrentUser() {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      return User(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
    }
    return null;
  }

  @override
  Future<void> logout() {
    return _authService.logout();
  }
}
