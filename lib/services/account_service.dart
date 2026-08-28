import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';

class AccountService {
  AccountService._();

  static final AccountService instance = AccountService._();

  bool get isAvailable =>
      FirebaseBootstrap.isConfigured && FirebaseBootstrap.isInitialized;

  FirebaseAuth get _auth {
    if (!isAvailable) {
      throw StateError('Firebase is not configured for this build.');
    }
    return FirebaseAuth.instance;
  }

  User? get currentUser => isAvailable ? FirebaseAuth.instance.currentUser : null;

  bool get isSignedIn => currentUser != null;

  Stream<User?> authStateChanges() {
    if (!isAvailable) return Stream<User?>.value(null);
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      await credential.user?.updateDisplayName(trimmedName);
      await credential.user?.reload();
    }

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-not-found':
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'wrong-password':
          return 'The email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Use a stronger password with at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'network-request-failed':
          return 'Could not reach Firebase. Check your internet connection.';
      }
      return error.message ?? 'Authentication failed.';
    }

    return error.toString();
  }
}
