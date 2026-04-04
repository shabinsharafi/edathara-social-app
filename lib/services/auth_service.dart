import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> getUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Stream<AppUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
    );
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await cred.user!.updateDisplayName(name);

    final user = AppUser(
      uid: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      isAdmin: false,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return AppUser.fromDoc(doc);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> grantAdmin(String email) async {
    final query = await _db.collection('users')
        .where('email', isEqualTo: email).limit(1).get();
    if (query.docs.isEmpty) throw Exception('User not found with that email');
    await query.docs.first.reference.update({'isAdmin': true});
  }

  Future<void> revokeAdmin(String uid) async {
    await _db.collection('users').doc(uid).update({'isAdmin': false});
  }

  Stream<List<AppUser>> adminUsersStream() {
    return _db.collection('users')
        .where('isAdmin', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
  }
}
