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

  // ─── Phone OTP ──────────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String error) failed,
    void Function(PhoneAuthCredential)? autoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        autoVerified?.call(credential);
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (e) => failed(_friendlyMessage(e)),
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  // ─── Error message mapper ────────────────────────────────────────────────────

  static String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'quota-exceeded':
        return 'SMS limit reached. Please try again later.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please check and try again.';
      case 'invalid-verification-id':
      case 'missing-verification-id':
        return 'Session expired. Please resend the OTP.';
      case 'session-expired':
        return 'OTP expired. Please request a new one.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'missing-phone-number':
        return 'Please enter your phone number.';
      case 'missing-verification-code':
        return 'Please enter the OTP.';
      case 'captcha-check-failed':
        return 'Security check failed. Please try again.';
      case 'app-not-authorized':
        return 'App not authorised for phone sign-in. Contact support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<AppUser> createPhoneUser({
    required String uid,
    required String name,
    required String phone,
  }) async {
    final user = AppUser(
      uid: uid,
      name: name,
      email: '',
      phone: phone,
      isAdmin: false,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  // ─── Admin Management ────────────────────────────────────────────────────────

  Future<void> grantAdminByPhone(String phone) async {
    final query = await _db.collection('users')
        .where('phone', isEqualTo: phone).limit(1).get();
    if (query.docs.isEmpty) throw Exception('No user found with that phone number');
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

  Future<void> grantTournamentAccessByPhone(String phone) async {
    final query = await _db.collection('users')
        .where('phone', isEqualTo: phone).limit(1).get();
    if (query.docs.isEmpty) throw Exception('No user found with that phone number');
    await query.docs.first.reference.update({'tournamentAccess': true});
  }

  Future<void> revokeTournamentAccess(String uid) async {
    await _db.collection('users').doc(uid).update({'tournamentAccess': false});
  }

  Stream<List<AppUser>> tournamentAccessUsersStream() {
    return _db.collection('users')
        .where('tournamentAccess', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
  }

  Stream<List<AppUser>> allUsersStream() {
    return _db.collection('users')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
  }
}
