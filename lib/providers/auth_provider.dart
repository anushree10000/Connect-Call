import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Single shared instance of the service — swap this in tests with a fake.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// The live Firebase auth stream. Splash/router watches this to decide
/// whether to show Login or Home.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Drives the login/register forms: loading + error state, independent of
/// the auth stream above so the form UI doesn't flicker on navigation.
class AuthFormState {
  final bool isLoading;
  final String? errorMessage;

  const AuthFormState({this.isLoading = false, this.errorMessage});

  AuthFormState copyWith({bool? isLoading, String? errorMessage}) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthFormNotifier extends StateNotifier<AuthFormState> {
  final AuthService _authService;

  AuthFormNotifier(this._authService) : super(const AuthFormState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.login(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authService.friendlyError(e),
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.register(name: name, email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authService.friendlyError(e),
      );
      return false;
    }
  }
}

final authFormProvider =
    StateNotifierProvider<AuthFormNotifier, AuthFormState>((ref) {
  return AuthFormNotifier(ref.watch(authServiceProvider));
});
