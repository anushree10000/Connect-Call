import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Wraps FirebaseAuth + the matching Firestore user doc so the rest of the
/// app never talks to FirebaseAuth directly. This is the seam you'd swap
/// out if you ever moved off Firebase.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Emits whenever auth state changes (login, logout, token refresh).
  /// The splash screen and app router both listen to this.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final userModel = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(userModel.toMap());

    await credential.user!.updateDisplayName(name.trim());

    return userModel;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'isOnline': true,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });

    final doc =
        await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      // Best-effort presence update; don't block logout if this fails.
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'isOnline': false,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      }).catchError((_) {});
    }
    await _auth.signOut();
  }

  /// Translates Firebase's error codes into messages a user can actually
  /// act on, instead of surfacing raw FirebaseAuthException text.
  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
