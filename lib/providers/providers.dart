import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greenfield_club/models/banner.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

// ─── Services ─────────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// ─── Auth State ───────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authServiceProvider).userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ─── Grounds ─────────────────────────────────────────────────────────────────
final groundsProvider = StreamProvider<List<PlayGround>>((ref) {
  return ref.watch(firestoreServiceProvider).groundsStream();
});

final allGroundsProvider = StreamProvider<List<PlayGround>>((ref) {
  return ref.watch(firestoreServiceProvider).allGroundsStream();
});

// ─── News ─────────────────────────────────────────────────────────────────────
final newsProvider = StreamProvider<List<NewsPost>>((ref) {
  return ref.watch(firestoreServiceProvider).newsStream();
});

// ─── Fundraisers ──────────────────────────────────────────────────────────────
final fundraisersProvider = StreamProvider<List<Fundraiser>>((ref) {
  return ref.watch(firestoreServiceProvider).fundraisersStream();
});

// ─── Contacts ─────────────────────────────────────────────────────────────────
final contactsProvider = StreamProvider<List<QuickContact>>((ref) {
  return ref.watch(firestoreServiceProvider).contactsStream();
});

// ─── Banners ─────────────────────────────────────────────────────────────────
final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(firestoreServiceProvider).bannersStream();
});

// ─── User Bookings ───────────────────────────────────────────────────────────
final userBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final user = ref.watch(currentAppUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).userBookingsStream(user.uid);
});

// ─── All Bookings (Admin) ─────────────────────────────────────────────────────
final allBookingsProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(firestoreServiceProvider).allBookingsStream();
});

// ─── Admin Users ──────────────────────────────────────────────────────────────
final adminUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(authServiceProvider).adminUsersStream();
});

// ─── Feedback (Admin) ─────────────────────────────────────────────────────────
final feedbackProvider = StreamProvider<List<ClubFeedback>>((ref) {
  return ref.watch(firestoreServiceProvider).feedbackStream();
});

// ─── Booking date selection ───────────────────────────────────────────────────
final selectedBookingDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final selectedGroundProvider = StateProvider<PlayGround?>((ref) => null);

// Taken slots for current ground + date
final takenSlotsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final ground = ref.watch(selectedGroundProvider);
  final date = ref.watch(selectedBookingDateProvider);
  if (ground == null) return {};
  return ref.watch(firestoreServiceProvider).getTakenSlots(
    groundId: ground.id,
    conflictIds: ground.conflictIds,
    date: date,
  );
});
