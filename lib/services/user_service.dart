import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null,
        );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? UserModel.fromMap(doc.data()!) : null;
  }

  /// Tous les utilisateurs sauf celui passé en paramètre, triés par nom.
  Stream<List<UserModel>> watchAllOtherUsers(String currentUid) {
    return _users.snapshots().map((snap) {
      return snap.docs
          .map((d) => UserModel.fromMap(d.data()))
          .where((u) => u.uid != currentUid)
          .toList()
        ..sort((a, b) => a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase()));
    });
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isEmpty) return;
    await _users.doc(uid).update(data);
  }
}
