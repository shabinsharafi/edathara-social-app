import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:greenfield_club/models/banner.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ─── Grounds ────────────────────────────────────────────────────────────────

  Stream<List<PlayGround>> groundsStream() {
    return _db.collection('grounds')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(PlayGround.fromDoc).toList());
  }

  Stream<List<PlayGround>> allGroundsStream() {
    return _db.collection('grounds')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(PlayGround.fromDoc).toList());
  }

  Future<void> addGround(PlayGround ground) async {
    await _db.collection('grounds').doc(ground.id).set(ground.toMap());
  }

  Future<void> updateGround(PlayGround ground) async {
    await _db.collection('grounds').doc(ground.id).update(ground.toMap());
  }

  Future<void> deleteGround(String groundId) async {
    await _db.collection('grounds').doc(groundId).delete();
  }

  Future<void> blockSlot(String groundId, String slot) async {
    await _db.collection('grounds').doc(groundId).update({
      'blockedSlots': FieldValue.arrayUnion([slot]),
    });
  }

  Future<void> unblockSlot(String groundId, String slot) async {
    await _db.collection('grounds').doc(groundId).update({
      'blockedSlots': FieldValue.arrayRemove([slot]),
    });
  }

  Future<void> updateConflicts(String groundId, List<String> conflictIds) async {
    await _db.collection('grounds').doc(groundId).update({
      'conflictIds': conflictIds,
    });
  }

  // ─── Bookings ────────────────────────────────────────────────────────────────

  Stream<List<Booking>> bookingsForDateStream(String dateKey) {
    // dateKey format: "2025-08-15"
    final date = DateTime.parse(dateKey);
    final start = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    final end = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));
    return _db.collection('bookings')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((s) => s.docs.map(Booking.fromDoc).toList());
  }

  Stream<List<Booking>> userBookingsStream(String userId) {
    return _db.collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('date')
        .limit(10)
        .snapshots()
        .map((s) => s.docs.map(Booking.fromDoc).toList());
  }

  Stream<List<Booking>> allBookingsStream() {
    return _db.collection('bookings')
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(Booking.fromDoc).toList());
  }

  Future<String> createBooking(Booking booking) async {
    final ref = _db.collection('bookings').doc();
    final b = Booking(
      id: ref.id,
      groundId: booking.groundId,
      groundName: booking.groundName,
      groundIcon: booking.groundIcon,
      slot: booking.slot,
      date: booking.date,
      userId: booking.userId,
      userName: booking.userName,
      userPhone: booking.userPhone,
      createdAt: DateTime.now(),
    );
    await ref.set(b.toMap());
    return ref.id;
  }

  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
    });
  }

  /// Returns set of slots already taken for a ground on a date
  /// Including conflict-ground slots
  Future<Set<String>> getTakenSlots({
    required String groundId,
    required List<String> conflictIds,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final allGroundIds = [groundId, ...conflictIds];
    final taken = <String>{};

    for (final gid in allGroundIds) {
      final snap = await _db.collection('bookings')
          .where('groundId', isEqualTo: gid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('status', isEqualTo: 'confirmed')
          .get();
      for (final doc in snap.docs) {
        taken.add(doc.data()['slot'] as String);
      }
    }
    return taken;
  }

  // ─── News ────────────────────────────────────────────────────────────────────

  Stream<List<NewsPost>> newsStream() {
    return _db.collection('news')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(NewsPost.fromDoc).toList());
  }

  Future<void> addNews({
    required String title,
    required String body,
    required String authorId,
    required String authorName,
    File? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      final ref = _storage.ref('news/${_uuid.v4()}');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }
    await _db.collection('news').add({
      'title': title,
      'body': body,
      'authorId': authorId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'likedBy': [],
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> toggleLike(String postId, String userId) async {
    final ref = _db.collection('news').doc(postId);
    final doc = await ref.get();
    final likedBy = List<String>.from((doc.data() as Map)['likedBy'] ?? []);
    if (likedBy.contains(userId)) {
      await ref.update({'likedBy': FieldValue.arrayRemove([userId])});
    } else {
      await ref.update({'likedBy': FieldValue.arrayUnion([userId])});
    }
  }

  Future<void> deleteNews(String postId) async {
    await _db.collection('news').doc(postId).delete();
  }

  // ─── Fundraisers ──────────────────────────────────────────────────────────────

  Stream<List<Fundraiser>> fundraisersStream() {
    return _db.collection('fundraisers')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Fundraiser.fromDoc).toList());
  }

  Future<void> addFundraiser(Fundraiser f, {File? imageFile}) async {
    String? imageUrl;
    if (imageFile != null) {
      final ref = _storage.ref('fundraisers/${_uuid.v4()}');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }
    final data = f.toMap();
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    await _db.collection('fundraisers').add(data);
  }

  Future<void> updateFundraiser(String id, Map<String, dynamic> data) async {
    await _db.collection('fundraisers').doc(id).update(data);
  }

  // ─── Feedback ─────────────────────────────────────────────────────────────────

  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required FeedbackType type,
    required String message,
    File? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      final ref = _storage.ref('feedback/${_uuid.v4()}');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }
    await _db.collection('feedback').add({
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'message': message,
      'imageUrl': imageUrl,
      'isResolved': false,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<ClubFeedback>> feedbackStream() {
    return _db.collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ClubFeedback.fromDoc).toList());
  }

  Future<void> resolveFeedback(String id) async {
    await _db.collection('feedback').doc(id).update({'isResolved': true});
  }

  // ─── Contacts ────────────────────────────────────────────────────────────────

  Stream<List<QuickContact>> contactsStream() {
    return _db.collection('contacts')
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs.map(QuickContact.fromDoc).toList());
  }

  Future<void> addContact(QuickContact c) async {
    await _db.collection('contacts').add(c.toMap());
  }

  Future<void> deleteContact(String id) async {
    await _db.collection('contacts').doc(id).delete();
  }

  // ─── Banners ─────────────────────────────────────────────────────────────────

  Stream<List<BannerModel>> bannersStream() {
    return _db.collection('banners')
        .orderBy('sortOrder')
        .snapshots()
        .map((s) => s.docs.map(BannerModel.fromDoc).toList());
  }

  Future<void> addBanner(BannerModel b, {File? imageFile}) async {
    String? imageUrl;
    if (imageFile != null) {
      final ref = _storage.ref('banners/${_uuid.v4()}');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }
    final data = b.toMap();
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    await _db.collection('banners').add(data);
  }

  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }
}
