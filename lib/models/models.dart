import 'package:cloud_firestore/cloud_firestore.dart';

// ─── User Model ───────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final bool isAdmin;
  final String? photoUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.isAdmin = false,
    this.photoUrl,
    required this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      isAdmin: d['isAdmin'] ?? false,
      photoUrl: d['photoUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'isAdmin': isAdmin,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AppUser copyWith({
    String? name, String? phone, bool? isAdmin, String? photoUrl,
  }) => AppUser(
    uid: uid, email: email, createdAt: createdAt,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    isAdmin: isAdmin ?? this.isAdmin,
    photoUrl: photoUrl ?? this.photoUrl,
  );
}

// ─── Ground Model ─────────────────────────────────────────────────────────────
class PlayGround {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final List<String> timeSlots;       // ["06:00","08:00",...]
  final List<String> blockedSlots;    // ["10:00",...]
  final List<String> conflictIds;     // other ground IDs that conflict
  final String description;
  final bool isActive;
  final int capacity;

  PlayGround({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.timeSlots,
    this.blockedSlots = const [],
    this.conflictIds = const [],
    this.description = '',
    this.isActive = true,
    this.capacity = 1,
  });

  factory PlayGround.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlayGround(
      id: doc.id,
      name: d['name'] ?? '',
      icon: d['icon'] ?? '🏟',
      colorHex: d['colorHex'] ?? '#1A5C3A',
      timeSlots: List<String>.from(d['timeSlots'] ?? []),
      blockedSlots: List<String>.from(d['blockedSlots'] ?? []),
      conflictIds: List<String>.from(d['conflictIds'] ?? []),
      description: d['description'] ?? '',
      isActive: d['isActive'] ?? true,
      capacity: d['capacity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'icon': icon,
    'colorHex': colorHex,
    'timeSlots': timeSlots,
    'blockedSlots': blockedSlots,
    'conflictIds': conflictIds,
    'description': description,
    'isActive': isActive,
    'capacity': capacity,
  };

  PlayGround copyWith({
    String? name, String? icon, String? colorHex, List<String>? timeSlots,
    List<String>? blockedSlots, List<String>? conflictIds, String? description,
    bool? isActive, int? capacity,
  }) => PlayGround(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    colorHex: colorHex ?? this.colorHex,
    timeSlots: timeSlots ?? this.timeSlots,
    blockedSlots: blockedSlots ?? this.blockedSlots,
    conflictIds: conflictIds ?? this.conflictIds,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    capacity: capacity ?? this.capacity,
  );
}

// ─── Booking Model ────────────────────────────────────────────────────────────
enum BookingStatus { confirmed, cancelled, pending }

class Booking {
  final String id;
  final String groundId;
  final String groundName;
  final String groundIcon;
  final String slot;
  final DateTime date;
  final String userId;
  final String userName;
  final String userPhone;
  final BookingStatus status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.groundId,
    required this.groundName,
    required this.groundIcon,
    required this.slot,
    required this.date,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    this.status = BookingStatus.confirmed,
    required this.createdAt,
  });

  factory Booking.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      groundId: d['groundId'] ?? '',
      groundName: d['groundName'] ?? '',
      groundIcon: d['groundIcon'] ?? '🏟',
      slot: d['slot'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? '',
      userPhone: d['userPhone'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == d['status'], orElse: () => BookingStatus.confirmed,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'groundId': groundId,
    'groundName': groundName,
    'groundIcon': groundIcon,
    'slot': slot,
    'date': Timestamp.fromDate(date),
    'userId': userId,
    'userName': userName,
    'userPhone': userPhone,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
}

// ─── News Model ───────────────────────────────────────────────────────────────
class NewsPost {
  final String id;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final String? imageUrl;
  final List<String> likedBy;
  final DateTime createdAt;

  NewsPost({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    this.imageUrl,
    this.likedBy = const [],
    required this.createdAt,
  });

  factory NewsPost.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NewsPost(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      imageUrl: d['imageUrl'],
      likedBy: List<String>.from(d['likedBy'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'authorId': authorId,
    'authorName': authorName,
    'imageUrl': imageUrl,
    'likedBy': likedBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  int get likeCount => likedBy.length;
  bool isLikedBy(String uid) => likedBy.contains(uid);
}

// ─── Fundraiser Model ─────────────────────────────────────────────────────────
class Fundraiser {
  final String id;
  final String title;
  final String description;
  final double goalAmount;
  final double raisedAmount;
  final String deadline;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  Fundraiser({
    required this.id,
    required this.title,
    required this.description,
    required this.goalAmount,
    this.raisedAmount = 0,
    required this.deadline,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory Fundraiser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Fundraiser(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      goalAmount: (d['goalAmount'] ?? 0).toDouble(),
      raisedAmount: (d['raisedAmount'] ?? 0).toDouble(),
      deadline: d['deadline'] ?? '',
      imageUrl: d['imageUrl'],
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'goalAmount': goalAmount,
    'raisedAmount': raisedAmount,
    'deadline': deadline,
    'imageUrl': imageUrl,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  double get progressPercent => (raisedAmount / goalAmount).clamp(0, 1);
}

// ─── Feedback Model ───────────────────────────────────────────────────────────
enum FeedbackType { suggestion, complaint }

class ClubFeedback {
  final String id;
  final String userId;
  final String userName;
  final FeedbackType type;
  final String message;
  final String? imageUrl;
  final bool isResolved;
  final DateTime createdAt;

  ClubFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.message,
    this.imageUrl,
    this.isResolved = false,
    required this.createdAt,
  });

  factory ClubFeedback.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubFeedback(
      id: doc.id,
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == d['type'], orElse: () => FeedbackType.suggestion,
      ),
      message: d['message'] ?? '',
      imageUrl: d['imageUrl'],
      isResolved: d['isResolved'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'type': type.name,
    'message': message,
    'imageUrl': imageUrl,
    'isResolved': isResolved,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─── Contact Model ────────────────────────────────────────────────────────────
class QuickContact {
  final String id;
  final String name;
  final String phone;
  final String role;
  final int sortOrder;

  QuickContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.sortOrder = 0,
  });

  factory QuickContact.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuickContact(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] ?? '',
      sortOrder: d['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 'phone': phone, 'role': role, 'sortOrder': sortOrder,
  };
}

