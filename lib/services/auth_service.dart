import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Crée un compte, initialise le document utilisateur, met à jour displayName.
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(displayName);

    final userModel = UserModel(
      uid: user.uid,
      email: email,
      displayName: displayName,
      photoUrl: null,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isOnline: true,
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());
    return userModel;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _setPresence(true);
  }

  Future<void> signOut() async {
    await _setPresence(false);
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> _setPresence(bool online) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'isOnline': online,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> setOnline(bool online) => _setPresence(online);

  /// Transforme un FirebaseAuthException en message lisible en français.
  static String humanizeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return "L'adresse email est invalide.";
        case 'user-disabled':
          return "Ce compte a été désactivé.";
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return "Email ou mot de passe incorrect.";
        case 'email-already-in-use':
          return "Cet email est déjà utilisé.";
        case 'weak-password':
          return "Mot de passe trop faible (6 caractères minimum).";
        case 'network-request-failed':
          return "Problème de connexion. Vérifiez votre réseau.";
        case 'too-many-requests':
          return "Trop de tentatives. Réessayez plus tard.";
        default:
          return error.message ?? "Une erreur est survenue.";
      }
    }
    return "Une erreur inattendue est survenue.";
  }
}
