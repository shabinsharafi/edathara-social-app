import 'package:cloud_firestore/cloud_firestore.dart';

// ─── User Model ───────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final bool isAdmin;
  final bool tournamentAccess;
  final String? photoUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.isAdmin = false,
    this.tournamentAccess = false,
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
      tournamentAccess: d['tournamentAccess'] ?? false,
      photoUrl: d['photoUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'isAdmin': isAdmin,
    'tournamentAccess': tournamentAccess,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AppUser copyWith({
    String? name, String? phone, bool? isAdmin, bool? tournamentAccess, String? photoUrl,
  }) => AppUser(
    uid: uid, email: email, createdAt: createdAt,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    isAdmin: isAdmin ?? this.isAdmin,
    tournamentAccess: tournamentAccess ?? this.tournamentAccess,
    photoUrl: photoUrl ?? this.photoUrl,
  );

  bool get canAccessTournaments => isAdmin || tournamentAccess;
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

// ─── Tournament Models ────────────────────────────────────────────────────────

enum TournamentFormat { league, knockout }
enum TournamentStatus { upcoming, ongoing, completed }
enum FixtureStatus { scheduled, live, completed, cancelled }

class Tournament {
  final String id;
  final String name;
  final String sport;
  final TournamentFormat format;
  final TournamentStatus status;
  final String createdBy;
  final String createdByName;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> scorekeeperUids; // users granted score-entry privilege
  final DateTime createdAt;
  final int? maxOvers;          // e.g. 20 for T20, 50 for ODI
  final int? playersPerSide;   // e.g. 11 (default)
  final int? maxOversPerBowler;// e.g. 4 for T20, 10 for ODI

  Tournament({
    required this.id,
    required this.name,
    required this.sport,
    required this.format,
    this.status = TournamentStatus.upcoming,
    required this.createdBy,
    required this.createdByName,
    this.startDate,
    this.endDate,
    this.scorekeeperUids = const [],
    required this.createdAt,
    this.maxOvers,
    this.playersPerSide,
    this.maxOversPerBowler,
  });

  factory Tournament.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Tournament(
      id: doc.id,
      name: d['name'] ?? '',
      sport: d['sport'] ?? '',
      format: TournamentFormat.values.firstWhere(
        (e) => e.name == d['format'], orElse: () => TournamentFormat.league,
      ),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == d['status'], orElse: () => TournamentStatus.upcoming,
      ),
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? '',
      startDate: (d['startDate'] as Timestamp?)?.toDate(),
      endDate: (d['endDate'] as Timestamp?)?.toDate(),
      scorekeeperUids: List<String>.from(d['scorekeeperUids'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxOvers: d['maxOvers'] as int?,
      playersPerSide: d['playersPerSide'] as int?,
      maxOversPerBowler: d['maxOversPerBowler'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'sport': sport,
    'format': format.name,
    'status': status.name,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'scorekeeperUids': scorekeeperUids,
    'createdAt': Timestamp.fromDate(createdAt),
    'maxOvers': maxOvers,
    'playersPerSide': playersPerSide,
    'maxOversPerBowler': maxOversPerBowler,
  };

  Tournament copyWith({
    String? name, String? sport, TournamentFormat? format,
    TournamentStatus? status, DateTime? startDate, DateTime? endDate,
    List<String>? scorekeeperUids, int? maxOvers, int? playersPerSide,
    int? maxOversPerBowler,
  }) => Tournament(
    id: id, createdBy: createdBy, createdByName: createdByName, createdAt: createdAt,
    name: name ?? this.name,
    sport: sport ?? this.sport,
    format: format ?? this.format,
    status: status ?? this.status,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    scorekeeperUids: scorekeeperUids ?? this.scorekeeperUids,
    maxOvers: maxOvers ?? this.maxOvers,
    playersPerSide: playersPerSide ?? this.playersPerSide,
    maxOversPerBowler: maxOversPerBowler ?? this.maxOversPerBowler,
  );

  bool canScore(String uid, bool isAdmin) =>
      isAdmin || scorekeeperUids.contains(uid);
}

class TournamentTeam {
  final String id;
  final String tournamentId;
  final String name;
  final String colorHex;
  final List<String> playerIds; // IDs of TournamentPlayers assigned to this team
  final DateTime createdAt;

  TournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.colorHex = '#1A5C3A',
    this.playerIds = const [],
    required this.createdAt,
  });

  factory TournamentTeam.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TournamentTeam(
      id: doc.id,
      tournamentId: d['tournamentId'] ?? '',
      name: d['name'] ?? '',
      colorHex: d['colorHex'] ?? '#1A5C3A',
      playerIds: List<String>.from(d['playerIds'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'name': name,
    'colorHex': colorHex,
    'playerIds': playerIds,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class Fixture {
  final String id;
  final String tournamentId;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final FixtureStatus status;
  final int round; // round number (1,2,3...)
  final String? venue;
  final DateTime? scheduledAt;
  final String? scoredByUid;
  final DateTime? scoredAt;
  // Toss
  final String? tossWinnerId;
  final String? tossWinnerName;
  final String? tossElected; // 'bat' | 'field'
  // Playing XI — list of TournamentPlayer IDs
  final List<String> homeXI;
  final List<String> awayXI;

  Fixture({
    required this.id,
    required this.tournamentId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    this.homeScore,
    this.awayScore,
    this.status = FixtureStatus.scheduled,
    this.round = 1,
    this.venue,
    this.scheduledAt,
    this.scoredByUid,
    this.scoredAt,
    this.tossWinnerId,
    this.tossWinnerName,
    this.tossElected,
    this.homeXI = const [],
    this.awayXI = const [],
  });

  bool get hasSetup => homeXI.isNotEmpty && awayXI.isNotEmpty;

  factory Fixture.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Fixture(
      id: doc.id,
      tournamentId: d['tournamentId'] ?? '',
      homeTeamId: d['homeTeamId'] ?? '',
      homeTeamName: d['homeTeamName'] ?? '',
      awayTeamId: d['awayTeamId'] ?? '',
      awayTeamName: d['awayTeamName'] ?? '',
      homeScore: d['homeScore'],
      awayScore: d['awayScore'],
      status: FixtureStatus.values.firstWhere(
        (e) => e.name == d['status'], orElse: () => FixtureStatus.scheduled,
      ),
      round: d['round'] ?? 1,
      venue: d['venue'],
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
      scoredByUid: d['scoredByUid'],
      scoredAt: (d['scoredAt'] as Timestamp?)?.toDate(),
      tossWinnerId: d['tossWinnerId'],
      tossWinnerName: d['tossWinnerName'],
      tossElected: d['tossElected'],
      homeXI: List<String>.from(d['homeXI'] ?? []),
      awayXI: List<String>.from(d['awayXI'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'homeTeamId': homeTeamId,
    'homeTeamName': homeTeamName,
    'awayTeamId': awayTeamId,
    'awayTeamName': awayTeamName,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'status': status.name,
    'round': round,
    'venue': venue,
    'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
    'scoredByUid': scoredByUid,
    'scoredAt': scoredAt != null ? Timestamp.fromDate(scoredAt!) : null,
    'tossWinnerId': tossWinnerId,
    'tossWinnerName': tossWinnerName,
    'tossElected': tossElected,
    'homeXI': homeXI,
    'awayXI': awayXI,
  };

  String get scoreDisplay {
    if (homeScore == null || awayScore == null) return 'vs';
    return '$homeScore - $awayScore';
  }

  String? get winner {
    if (homeScore == null || awayScore == null) return null;
    if (homeScore! > awayScore!) return homeTeamId;
    if (awayScore! > homeScore!) return awayTeamId;
    return 'draw';
  }
}

// League standing helper (computed client-side from fixtures)
class TeamStanding {
  final String teamId;
  final String teamName;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  TeamStanding({required this.teamId, required this.teamName});

  int get points => won * 3 + drawn;
  int get goalDiff => goalsFor - goalsAgainst;
}

// ─── Tournament Player Model ──────────────────────────────────────────────────
class TournamentPlayer {
  final String id;
  final String tournamentId;
  final String name;
  final String phone;
  final String? jerseyNumber;
  final String? teamId;   // null = unassigned
  final String? teamName;
  final String? photoUrl;
  final DateTime createdAt;

  TournamentPlayer({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.phone = '',
    this.jerseyNumber,
    this.teamId,
    this.teamName,
    this.photoUrl,
    required this.createdAt,
  });

  factory TournamentPlayer.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TournamentPlayer(
      id: doc.id,
      tournamentId: d['tournamentId'] ?? '',
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      jerseyNumber: d['jerseyNumber'],
      teamId: d['teamId'],
      teamName: d['teamName'],
      photoUrl: d['photoUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'name': name,
    'phone': phone,
    'jerseyNumber': jerseyNumber,
    'teamId': teamId,
    'teamName': teamName,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  TournamentPlayer copyWith({
    String? teamId, String? teamName, String? jerseyNumber, String? photoUrl,
  }) => TournamentPlayer(
        id: id, tournamentId: tournamentId, name: name, phone: phone,
        createdAt: createdAt,
        jerseyNumber: jerseyNumber ?? this.jerseyNumber,
        teamId: teamId ?? this.teamId,
        teamName: teamName ?? this.teamName,
        photoUrl: photoUrl ?? this.photoUrl,
      );

  bool get isAssigned => teamId != null && teamId!.isNotEmpty;
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

