import '../../repositories/auth_repository.dart';
import '../../entities/user.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<User?> execute(String email, String password) {
    return _authRepository.login(email, password);
  }
}
