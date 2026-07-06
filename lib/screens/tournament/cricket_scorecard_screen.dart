import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'cricket_live_scoring_screen.dart';

final _db = FirebaseFirestore.instance;

const _kRed = Color(0xFFC62828);

// ─── Theme constants ──────────────────────────────────────────────────────────
const _kGreen      = Color(0xFF1B5E20);
const _kGreenLight = Color(0xFF2E7D32);
const _kGreenAccent= Color(0xFF43A047);
const _kGreenBg    = Color(0xFFE8F5E9);
const _kBg         = Color(0xFFF2F2F2);
const _kCard       = Colors.white;
const _kDivider    = Color(0xFFE0E0E0);
const _kTextPrimary= Color(0xFF202124);
const _kTextSecondary = Color(0xFF5F6368);
const _kTextLight  = Color(0xFF9AA0A6);
const _kLive       = Color(0xFFE53935);
const _kHeaderBg   = Color(0xFF1565C0); // Google blue for match header

// ─── Local models ─────────────────────────────────────────────────────────────
class CricketInnings {
  final String id, fixtureId, tournamentId;
  final String battingTeamId, battingTeamName;
  final String bowlingTeamId, bowlingTeamName;
  final int inningsNumber;
  int totalRuns, totalWickets, overs, balls;
  int wides, noBalls, byes, legByes;
  bool isCompleted;

  CricketInnings({
    required this.id, required this.fixtureId, required this.tournamentId,
    required this.battingTeamId, required this.battingTeamName,
    required this.bowlingTeamId, required this.bowlingTeamName,
    required this.inningsNumber,
    this.totalRuns = 0, this.totalWickets = 0,
    this.overs = 0, this.balls = 0,
    this.wides = 0, this.noBalls = 0, this.byes = 0, this.legByes = 0,
    this.isCompleted = false,
  });

  int get extras => wides + noBalls + byes + legByes;
  String get overDisplay => balls == 0 ? '$overs.0' : '$overs.$balls';
  double get runRate {
    final total = overs + balls / 6;
    return total == 0 ? 0.0 : totalRuns / total;
  }

  factory CricketInnings.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CricketInnings(
      id: doc.id, fixtureId: d['fixtureId'] ?? '',
      tournamentId: d['tournamentId'] ?? '',
      battingTeamId: d['battingTeamId'] ?? '', battingTeamName: d['battingTeamName'] ?? '',
      bowlingTeamId: d['bowlingTeamId'] ?? '', bowlingTeamName: d['bowlingTeamName'] ?? '',
      inningsNumber: d['inningsNumber'] ?? 1,
      totalRuns: d['totalRuns'] ?? 0, totalWickets: d['totalWickets'] ?? 0,
      overs: d['overs'] ?? 0, balls: d['balls'] ?? 0,
      wides: d['wides'] ?? 0, noBalls: d['noBalls'] ?? 0,
      byes: d['byes'] ?? 0, legByes: d['legByes'] ?? 0,
      isCompleted: d['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'fixtureId': fixtureId, 'tournamentId': tournamentId,
    'battingTeamId': battingTeamId, 'battingTeamName': battingTeamName,
    'bowlingTeamId': bowlingTeamId, 'bowlingTeamName': bowlingTeamName,
    'inningsNumber': inningsNumber,
    'totalRuns': totalRuns, 'totalWickets': totalWickets,
    'overs': overs, 'balls': balls,
    'wides': wides, 'noBalls': noBalls, 'byes': byes, 'legByes': legByes,
    'isCompleted': isCompleted,
  };
}

class BattingScore {
  final String id, inningsId, fixtureId, tournamentId;
  final String playerId, playerName, teamId;
  int runs, balls, fours, sixes, battingPosition;
  String dismissal, bowlerId, bowlerName, fielderId, fielderName;

  BattingScore({
    required this.id, required this.inningsId, required this.fixtureId,
    required this.tournamentId, required this.playerId, required this.playerName,
    required this.teamId,
    this.runs = 0, this.balls = 0, this.fours = 0, this.sixes = 0,
    this.dismissal = 'batting',
    this.bowlerId = '', this.bowlerName = '',
    this.fielderId = '', this.fielderName = '',
    this.battingPosition = 99,
  });

  bool get isOut => dismissal != 'notOut' && dismissal != 'batting';
  bool get isBatting => dismissal == 'batting';
  double get strikeRate => balls == 0 ? 0 : runs / balls * 100;

  String get dismissalText {
    switch (dismissal) {
      case 'batting': return 'batting';
      case 'notOut': return 'not out';
      case 'bowled': return 'b $bowlerName';
      case 'caught':
        return fielderName.isEmpty ? 'c & b $bowlerName' : 'c $fielderName b $bowlerName';
      case 'lbw': return 'lbw b $bowlerName';
      case 'runOut': return fielderName.isEmpty ? 'run out' : 'run out ($fielderName)';
      case 'stumped': return 'st $fielderName b $bowlerName';
      case 'hitWicket': return 'hit wicket b $bowlerName';
      case 'retired': return 'retired';
      default: return dismissal;
    }
  }

  factory BattingScore.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BattingScore(
      id: doc.id, inningsId: d['inningsId'] ?? '',
      fixtureId: d['fixtureId'] ?? '', tournamentId: d['tournamentId'] ?? '',
      playerId: d['playerId'] ?? '', playerName: d['playerName'] ?? '',
      teamId: d['teamId'] ?? '',
      runs: d['runs'] ?? 0, balls: d['balls'] ?? 0,
      fours: d['fours'] ?? 0, sixes: d['sixes'] ?? 0,
      dismissal: d['dismissal'] ?? 'batting',
      bowlerId: d['bowlerId'] ?? '', bowlerName: d['bowlerName'] ?? '',
      fielderId: d['fielderId'] ?? '', fielderName: d['fielderName'] ?? '',
      battingPosition: d['battingPosition'] ?? 99,
    );
  }

  Map<String, dynamic> toMap() => {
    'inningsId': inningsId, 'fixtureId': fixtureId, 'tournamentId': tournamentId,
    'playerId': playerId, 'playerName': playerName, 'teamId': teamId,
    'runs': runs, 'balls': balls, 'fours': fours, 'sixes': sixes,
    'dismissal': dismissal, 'bowlerId': bowlerId, 'bowlerName': bowlerName,
    'fielderId': fielderId, 'fielderName': fielderName, 'battingPosition': battingPosition,
  };
}

class BowlingFigure {
  final String id, inningsId, fixtureId, tournamentId;
  final String playerId, playerName, teamId;
  int overs, balls, maidens, runs, wickets, wides, noBalls, bowlingOrder;

  BowlingFigure({
    required this.id, required this.inningsId, required this.fixtureId,
    required this.tournamentId, required this.playerId, required this.playerName,
    required this.teamId,
    this.overs = 0, this.balls = 0, this.maidens = 0,
    this.runs = 0, this.wickets = 0, this.wides = 0, this.noBalls = 0,
    this.bowlingOrder = 99,
  });

  double get economy => overs == 0 ? 0 : runs / overs;
  String get oversDisplay => balls == 0 ? '$overs.0' : '$overs.$balls';

  factory BowlingFigure.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BowlingFigure(
      id: doc.id, inningsId: d['inningsId'] ?? '',
      fixtureId: d['fixtureId'] ?? '', tournamentId: d['tournamentId'] ?? '',
      playerId: d['playerId'] ?? '', playerName: d['playerName'] ?? '',
      teamId: d['teamId'] ?? '',
      overs: d['overs'] ?? 0, balls: d['balls'] ?? 0, maidens: d['maidens'] ?? 0,
      runs: d['runs'] ?? 0, wickets: d['wickets'] ?? 0,
      wides: d['wides'] ?? 0, noBalls: d['noBalls'] ?? 0,
      bowlingOrder: d['bowlingOrder'] ?? 99,
    );
  }

  Map<String, dynamic> toMap() => {
    'inningsId': inningsId, 'fixtureId': fixtureId, 'tournamentId': tournamentId,
    'playerId': playerId, 'playerName': playerName, 'teamId': teamId,
    'overs': overs, 'balls': balls, 'maidens': maidens, 'runs': runs,
    'wickets': wickets, 'wides': wides, 'noBalls': noBalls, 'bowlingOrder': bowlingOrder,
  };
}

// ─── Streams (no orderBy → client-side sort to avoid composite index) ─────────
Stream<List<CricketInnings>> _inningsStream(String fixtureId) =>
    _db.collection('cricketInnings')
        .where('fixtureId', isEqualTo: fixtureId)
        .snapshots()
        .map((s) {
          final l = s.docs.map(CricketInnings.fromDoc).toList();
          l.sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
          return l;
        });

Stream<List<BattingScore>> _battingStream(String inningsId) =>
    _db.collection('battingScores')
        .where('inningsId', isEqualTo: inningsId)
        .snapshots()
        .map((s) {
          final l = s.docs.map(BattingScore.fromDoc).toList();
          l.sort((a, b) => a.battingPosition.compareTo(b.battingPosition));
          return l;
        });

Stream<List<BowlingFigure>> _bowlingStream(String inningsId) =>
    _db.collection('bowlingFigures')
        .where('inningsId', isEqualTo: inningsId)
        .snapshots()
        .map((s) {
          final l = s.docs.map(BowlingFigure.fromDoc).toList();
          l.sort((a, b) => a.bowlingOrder.compareTo(b.bowlingOrder));
          return l;
        });

// ═══════════════════════════════════════════════════════════════════════════════
// ROOT SCREEN — streams live fixture, branches to Setup or Scorecard
// ═══════════════════════════════════════════════════════════════════════════════
class CricketScorecardScreen extends ConsumerStatefulWidget {
  final Fixture fixture;
  final Tournament tournament;
  final bool canScore;
  final String currentUid;

  const CricketScorecardScreen({
    super.key,
    required this.fixture,
    required this.tournament,
    required this.canScore,
    required this.currentUid,
  });

  @override
  ConsumerState<CricketScorecardScreen> createState() =>
      _CricketScorecardScreenState();
}

class _CricketScorecardScreenState extends ConsumerState<CricketScorecardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Stream<Fixture> get _fixtureStream => _db
      .collection('tournaments').doc(widget.tournament.id)
      .collection('fixtures').doc(widget.fixture.id)
      .snapshots()
      .map(Fixture.fromDoc);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Fixture>(
      stream: _fixtureStream,
      initialData: widget.fixture,
      builder: (context, snap) {
        final fixture = snap.data ?? widget.fixture;
        if (!fixture.hasSetup) {
          return _MatchSetupScreen(
            fixture: fixture,
            tournament: widget.tournament,
            canScore: widget.canScore,
          );
        }
        return _ScorecardView(
          fixture: fixture,
          tournament: widget.tournament,
          canScore: widget.canScore,
          tab: _tab,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCORECARD VIEW
// ═══════════════════════════════════════════════════════════════════════════════
class _ScorecardView extends ConsumerWidget {
  final Fixture fixture;
  final Tournament tournament;
  final bool canScore;
  final TabController tab;

  const _ScorecardView({
    required this.fixture, required this.tournament,
    required this.canScore, required this.tab,
  });

  String _otherId() => fixture.tossWinnerId == fixture.homeTeamId
      ? fixture.awayTeamId : fixture.homeTeamId;
  String _otherName() => fixture.tossWinnerId == fixture.homeTeamId
      ? fixture.awayTeamName : fixture.homeTeamName;

  Future<void> _startInnings(BuildContext context, List<CricketInnings> existing, int number) async {
    String batId, batName, bowlId, bowlName;
    if (number == 1) {
      final batFirst = fixture.tossElected == 'bat';
      batId   = batFirst ? fixture.tossWinnerId! : _otherId();
      batName = batFirst ? fixture.tossWinnerName! : _otherName();
      bowlId   = batFirst ? _otherId() : fixture.tossWinnerId!;
      bowlName = batFirst ? _otherName() : fixture.tossWinnerName!;
    } else {
      batId   = existing.first.bowlingTeamId;
      batName = existing.first.bowlingTeamName;
      bowlId   = existing.first.battingTeamId;
      bowlName = existing.first.battingTeamName;
    }
    final ref = _db.collection('cricketInnings').doc();
    await ref.set(CricketInnings(
      id: ref.id, fixtureId: fixture.id, tournamentId: tournament.id,
      battingTeamId: batId, battingTeamName: batName,
      bowlingTeamId: bowlId, bowlingTeamName: bowlName,
      inningsNumber: number,
    ).toMap());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<CricketInnings>>(
      stream: _inningsStream(fixture.id),
      builder: (context, snap) {
        if (snap.hasError) {
          return _ErrorScaffold(error: snap.error.toString());
        }
        final innings = snap.data ?? [];
        final liveInnings = innings.isNotEmpty ? innings.last : null;

        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fixture.homeTeamName} vs ${fixture.awayTeamName}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(tournament.name,
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
            actions: [
              if (canScore)
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'Innings',
                  onSelected: (n) => _startInnings(context, innings, n),
                  itemBuilder: (_) => [
                    if (!innings.any((i) => i.inningsNumber == 1))
                      const PopupMenuItem(value: 1, child: Text('Start 1st Innings')),
                    if (innings.any((i) => i.inningsNumber == 1) &&
                        !innings.any((i) => i.inningsNumber == 2))
                      const PopupMenuItem(value: 2, child: Text('Start 2nd Innings')),
                  ],
                ),
            ],
          ),
          floatingActionButton: canScore && liveInnings != null && !liveInnings.isCompleted
              ? FloatingActionButton.extended(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  icon: const Text('🏏', style: TextStyle(fontSize: 18)),
                  label: const Text('SCORE',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          letterSpacing: 1, fontSize: 13)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CricketLiveScoringScreen(
                        inningsId: liveInnings.id,
                        tournamentId: tournament.id,
                        fixtureId: fixture.id,
                        maxOvers: tournament.maxOvers,
                        playersPerSide: tournament.playersPerSide,
                        maxOversPerBowler: tournament.maxOversPerBowler,
                      ),
                    ),
                  ),
                )
              : null,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Match summary card (Google style) ──────────────────────
              _MatchSummaryCard(fixture: fixture, innings: innings),
              // ── Toss info ──────────────────────────────────────────────
              if (fixture.tossWinnerName != null)
                _TossInfoBar(fixture: fixture),
              const SizedBox(height: 8),
              // ── Innings content ────────────────────────────────────────
              innings.isEmpty
                  ? _NoInningsPlaceholder(
                      fixture: fixture,
                      canScore: canScore,
                      onStart: () => _startInnings(context, innings, 1),
                    )
                  : _InningsTabs(
                      innings: innings,
                      fixture: fixture,
                      tournament: tournament,
                      canScore: canScore,
                    ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ─── Google-style Match Summary Card ─────────────────────────────────────────
class _MatchSummaryCard extends StatelessWidget {
  final Fixture fixture;
  final List<CricketInnings> innings;
  const _MatchSummaryCard({required this.fixture, required this.innings});

  @override
  Widget build(BuildContext context) {
    final inn1 = innings.where((i) => i.inningsNumber == 1).firstOrNull;
    final inn2 = innings.where((i) => i.inningsNumber == 2).firstOrNull;
    final isLive = innings.isNotEmpty && !innings.last.isCompleted;

    return Container(
      color: _kGreen,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Live chip
          if (isLive)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kLive,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Colors.white),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ],
                ),
              ),
            ),
          // Team scores row
          Row(
            children: [
              // Home team
              Expanded(child: _TeamScoreBlock(
                teamName: fixture.homeTeamName,
                innings: inn1?.battingTeamId == fixture.homeTeamId ? inn1
                    : inn2?.battingTeamId == fixture.homeTeamId ? inn2 : null,
                isActive: isLive && innings.last.battingTeamId == fixture.homeTeamId,
              )),
              // VS divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const Text('vs', style: TextStyle(
                        color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Away team
              Expanded(child: _TeamScoreBlock(
                teamName: fixture.awayTeamName,
                innings: inn1?.battingTeamId == fixture.awayTeamId ? inn1
                    : inn2?.battingTeamId == fixture.awayTeamId ? inn2 : null,
                isActive: isLive && innings.last.battingTeamId == fixture.awayTeamId,
                alignRight: true,
              )),
            ],
          ),
          // Match status line
          if (innings.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MatchStatusLine(innings: innings, fixture: fixture),
          ],
        ],
      ),
    );
  }
}

class _TeamScoreBlock extends StatelessWidget {
  final String teamName;
  final CricketInnings? innings;
  final bool isActive;
  final bool alignRight;
  const _TeamScoreBlock({
    required this.teamName, required this.innings,
    required this.isActive, this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cross = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(
          teamName,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (innings != null) ...[
          Text(
            '${innings!.totalRuns}/${innings!.totalWickets}',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: isActive ? 26 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '(${innings!.overDisplay} ov)',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ] else
          const Text('–', style: TextStyle(color: Colors.white38, fontSize: 20,
              fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MatchStatusLine extends StatelessWidget {
  final List<CricketInnings> innings;
  final Fixture fixture;
  const _MatchStatusLine({required this.innings, required this.fixture});

  @override
  Widget build(BuildContext context) {
    final last = innings.last;
    String status;
    if (!last.isCompleted) {
      status = 'CRR: ${last.runRate.toStringAsFixed(2)}';
      // Add required run rate for 2nd innings
      if (last.inningsNumber == 2) {
        final inn1 = innings.firstWhere((i) => i.inningsNumber == 1);
        final target = inn1.totalRuns + 1;
        final need = target - last.totalRuns;
        final ovRemaining = ((fixture.homeXI.length > 0 ? 20 : 20) - last.overs - last.balls / 6);
        final rrr = ovRemaining > 0 ? need / ovRemaining : 0.0;
        status = 'Target: $target  ·  Need $need off ${(ovRemaining).toStringAsFixed(1)} ov  ·  RRR: ${rrr.toStringAsFixed(2)}';
      }
    } else {
      if (innings.length == 2) {
        final inn1 = innings.first;
        final inn2 = innings.last;
        if (inn2.totalRuns > inn1.totalRuns) {
          final wicketsLeft = 10 - inn2.totalWickets;
          status = '${inn2.battingTeamName} won by $wicketsLeft wickets';
        } else if (inn1.totalRuns > inn2.totalRuns) {
          final runDiff = inn1.totalRuns - inn2.totalRuns;
          status = '${inn1.battingTeamName} won by $runDiff runs';
        } else {
          status = 'Match tied';
        }
      } else {
        status = '${last.battingTeamName}: ${last.totalRuns}/${last.totalWickets}';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 11),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TossInfoBar extends StatelessWidget {
  final Fixture fixture;
  const _TossInfoBar({required this.fixture});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text('🪙 ', style: TextStyle(fontSize: 13)),
            Expanded(
              child: Text(
                '${fixture.tossWinnerName} won toss, elected to ${fixture.tossElected}',
                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

// ─── No innings placeholder ───────────────────────────────────────────────────
class _NoInningsPlaceholder extends StatelessWidget {
  final Fixture fixture;
  final bool canScore;
  final VoidCallback onStart;
  const _NoInningsPlaceholder({required this.fixture, required this.canScore, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final batFirst = fixture.tossElected == 'bat'
        ? fixture.tossWinnerName
        : (fixture.tossWinnerId == fixture.homeTeamId
            ? fixture.awayTeamName : fixture.homeTeamName);
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏏', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('$batFirst bats first',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextPrimary)),
          const SizedBox(height: 4),
          Text('Match not yet started',
              style: const TextStyle(color: _kTextSecondary, fontSize: 13)),
          if (canScore) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kGreenLight),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start 1st Innings'),
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Innings tabs ─────────────────────────────────────────────────────────────
class _InningsTabs extends ConsumerStatefulWidget {
  final List<CricketInnings> innings;
  final Fixture fixture;
  final Tournament tournament;
  final bool canScore;
  const _InningsTabs({required this.innings, required this.fixture,
      required this.tournament, required this.canScore});

  @override
  ConsumerState<_InningsTabs> createState() => _InningsTabsState();
}

class _InningsTabsState extends ConsumerState<_InningsTabs>
    with TickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.innings.length, vsync: this);
    if (widget.innings.length > 1) _tab.index = widget.innings.length - 1;
    _tab.addListener(() { if (!_tab.indexIsChanging) setState(() {}); });
  }

  @override
  void didUpdateWidget(_InningsTabs old) {
    super.didUpdateWidget(old);
    if (old.innings.length != widget.innings.length) {
      _tab.dispose();
      _tab = TabController(length: widget.innings.length, vsync: this);
      _tab.index = widget.innings.length - 1;
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.innings.length == 1) {
      return _SingleInningsBody(
        innings: widget.innings.first,
        fixture: widget.fixture,
        tournament: widget.tournament,
        canScore: widget.canScore,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: _kGreenLight,
            unselectedLabelColor: _kTextSecondary,
            indicatorColor: _kGreenLight,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: widget.innings.map((i) => Tab(
              text: i.inningsNumber == 1 ? '1st Inn' : '2nd Inn',
            )).toList(),
          ),
        ),
        // Use IndexedStack so both innings stay mounted (no height issue)
        IndexedStack(
          index: _tab.index,
          children: widget.innings.map((i) => _SingleInningsBody(
            innings: i,
            fixture: widget.fixture,
            tournament: widget.tournament,
            canScore: widget.canScore,
          )).toList(),
        ),
      ],
    );
  }
}

// ─── Single innings body ──────────────────────────────────────────────────────
class _SingleInningsBody extends ConsumerWidget {
  final CricketInnings innings;
  final Fixture fixture;
  final Tournament tournament;
  final bool canScore;
  const _SingleInningsBody({required this.innings, required this.fixture,
      required this.tournament, required this.canScore});

  List<String> get _battingXI => innings.battingTeamId == fixture.homeTeamId
      ? fixture.homeXI : fixture.awayXI;
  List<String> get _bowlingXI => innings.battingTeamId == fixture.homeTeamId
      ? fixture.awayXI : fixture.homeXI;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPlayers =
        ref.watch(tournamentPlayersProvider(tournament.id)).valueOrNull ?? [];

    return StreamBuilder<List<BattingScore>>(
      stream: _battingStream(innings.id),
      builder: (_, batSnap) {
        final batting = batSnap.data ?? [];
        return StreamBuilder<List<BowlingFigure>>(
          stream: _bowlingStream(innings.id),
          builder: (_, bowlSnap) {
            final bowling = bowlSnap.data ?? [];

            final batPlayers = allPlayers.where((p) => _battingXI.contains(p.id)).toList();
            final bowlPlayers = allPlayers.where((p) => _bowlingXI.contains(p.id)).toList();
            final appearedIds = batting.map((b) => b.playerId).toSet();
            final yetToBat = batPlayers.where((p) => !appearedIds.contains(p.id)).toList();
            final bowledIds = bowling.map((b) => b.playerId).toSet();
            final yetToBowl = bowlPlayers.where((p) => !bowledIds.contains(p.id)).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InningsSummaryBar(innings: innings, canScore: canScore),
                const SizedBox(height: 8),
                _BattingCard(
                  innings: innings, fixture: fixture, tournament: tournament,
                  batting: batting, yetToBat: yetToBat,
                  bowlingPlayers: bowlPlayers, canScore: canScore,
                ),
                const SizedBox(height: 8),
                _BowlingCard(
                  innings: innings, fixture: fixture, tournament: tournament,
                  bowling: bowling, yetToBowl: yetToBowl,
                  canScore: canScore,
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Innings summary bar (Google style) ──────────────────────────────────────
class _InningsSummaryBar extends StatelessWidget {
  final CricketInnings innings;
  final bool canScore;
  const _InningsSummaryBar({required this.innings, required this.canScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  innings.battingTeamName,
                  style: const TextStyle(
                      fontSize: 11, color: _kTextSecondary, fontWeight: FontWeight.w500,
                      letterSpacing: 0.2),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${innings.totalRuns}/${innings.totalWickets}',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold,
                          color: _kTextPrimary, height: 1.1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${innings.overDisplay} ov)',
                      style: const TextStyle(fontSize: 13, color: _kTextSecondary),
                    ),
                  ],
                ),
                if (innings.extras > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Extras ${innings.extras}'
                    '  (wd ${innings.wides}  nb ${innings.noBalls}'
                    '  b ${innings.byes}  lb ${innings.legByes})',
                    style: const TextStyle(fontSize: 11, color: _kTextLight),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGreenBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CRR  ${innings.runRate.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _kGreen),
                ),
              ),
              if (canScore) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => _InningsEditDialog(innings: innings),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: _kTextSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Batting Card ─────────────────────────────────────────────────────────────
class _BattingCard extends StatelessWidget {
  final CricketInnings innings;
  final Fixture fixture;
  final Tournament tournament;
  final List<BattingScore> batting;
  final List<TournamentPlayer> yetToBat;
  final List<TournamentPlayer> bowlingPlayers;
  final bool canScore;

  const _BattingCard({
    required this.innings, required this.fixture, required this.tournament,
    required this.batting, required this.yetToBat,
    required this.bowlingPlayers, required this.canScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardSectionHeader(
            title: 'BATTING',
            action: canScore
                ? _GreenTextBtn(
                    label: '+ Add',
                    onTap: yetToBat.isEmpty ? null : () => _pickBatsman(context),
                  )
                : null,
          ),
          const _BatColHeader(),
          ...batting.asMap().entries.map((e) => _BatRow(
                score: e.value,
                innings: innings,
                bowlingPlayers: bowlingPlayers,
                canScore: canScore,
                isLast: e.key == batting.length - 1,
              )),
          if (batting.isNotEmpty) ...[
            _ExtrasRow(innings: innings),
            _TotalRow(innings: innings),
          ],
          if (yetToBat.isNotEmpty)
            _YetToBatRow(players: yetToBat),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _pickBatsman(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PickPlayerSheet(
        title: 'Select Batsman',
        players: yetToBat,
        color: _kGreenLight,
        onPick: (p) async {
          await _db.collection('battingScores').add({
            'inningsId': innings.id, 'fixtureId': innings.fixtureId,
            'tournamentId': innings.tournamentId,
            'playerId': p.id, 'playerName': p.name, 'teamId': innings.battingTeamId,
            'runs': 0, 'balls': 0, 'fours': 0, 'sixes': 0, 'dismissal': 'batting',
            'bowlerId': '', 'bowlerName': '', 'fielderId': '', 'fielderName': '',
            'battingPosition': batting.length + 1,
          });
        },
      ),
    );
  }
}

class _BatColHeader extends StatelessWidget {
  const _BatColHeader();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF8F9FA),
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        child: Row(
          children: const [
            Expanded(flex: 10, child: Text('BATTER', style: _colHeadStyle)),
            _ColH('R'),
            _ColH('B'),
            _ColH('4s'),
            _ColH('6s'),
            _ColH('SR'),
          ],
        ),
      );
}

class _BatRow extends StatelessWidget {
  final BattingScore score;
  final CricketInnings innings;
  final List<TournamentPlayer> bowlingPlayers;
  final bool canScore;
  final bool isLast;
  const _BatRow({required this.score, required this.innings,
      required this.bowlingPlayers, required this.canScore, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isBatting = score.isBatting;
    return InkWell(
      onTap: canScore
          ? () => showDialog(
                context: context,
                builder: (_) => _BattingEditDialog(
                    score: score, innings: innings, bowlingPlayers: bowlingPlayers),
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isBatting ? const Color(0xFFF0FBF0) : Colors.white,
          border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isBatting)
                        Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.only(right: 5, top: 1),
                          decoration: const BoxDecoration(
                            color: _kGreenAccent, shape: BoxShape.circle),
                        ),
                      Expanded(
                        child: Text(
                          score.playerName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isBatting ? _kGreen : _kTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.dismissalText,
                    style: TextStyle(
                      fontSize: 11,
                      color: score.isOut ? _kTextSecondary : _kTextLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _ColV('${score.runs}', bold: true,
                color: score.runs >= 50 ? const Color(0xFFE65100) : null),
            _ColV('${score.balls}'),
            _ColV('${score.fours}'),
            _ColV('${score.sixes}',
                color: score.sixes > 0 ? _kGreen : null),
            _ColV(score.strikeRate.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }
}

class _ExtrasRow extends StatelessWidget {
  final CricketInnings innings;
  const _ExtrasRow({required this.innings});

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF8F9FA),
        padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
        child: Row(
          children: [
            const Expanded(
              flex: 10,
              child: Text('Extras',
                  style: TextStyle(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500)),
            ),
            _ColV('${innings.extras}', bold: true),
            Expanded(
              flex: 20,
              child: Text(
                '  wd ${innings.wides}  nb ${innings.noBalls}  b ${innings.byes}  lb ${innings.legByes}',
                style: const TextStyle(fontSize: 11, color: _kTextLight),
              ),
            ),
          ],
        ),
      );
}

class _TotalRow extends StatelessWidget {
  final CricketInnings innings;
  const _TotalRow({required this.innings});

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF8F9FA),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _kDivider)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(
                innings.battingTeamName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                    color: _kTextPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${innings.totalRuns}/${innings.totalWickets}  (${innings.overDisplay} Ov)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
}

class _YetToBatRow extends StatelessWidget {
  final List<TournamentPlayer> players;
  const _YetToBatRow({required this.players});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _kDivider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yet to bat',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: _kTextLight, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(
              players.map((p) => p.name).join('  ·  '),
              style: const TextStyle(fontSize: 12, color: _kTextSecondary),
            ),
          ],
        ),
      );
}

// ─── Bowling Card ─────────────────────────────────────────────────────────────
class _BowlingCard extends StatelessWidget {
  final CricketInnings innings;
  final Fixture fixture;
  final Tournament tournament;
  final List<BowlingFigure> bowling;
  final List<TournamentPlayer> yetToBowl;
  final bool canScore;

  const _BowlingCard({
    required this.innings, required this.fixture, required this.tournament,
    required this.bowling, required this.yetToBowl, required this.canScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      child: Column(
        children: [
          _CardSectionHeader(
            title: 'BOWLING',
            action: canScore
                ? _GreenTextBtn(
                    label: '+ Add',
                    onTap: yetToBowl.isEmpty ? null : () => _pickBowler(context),
                  )
                : null,
          ),
          const _BowlColHeader(),
          ...bowling.map((b) => _BowlRow(
                figure: b, innings: innings, canScore: canScore,
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _pickBowler(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PickPlayerSheet(
        title: 'Select Bowler',
        players: yetToBowl,
        color: Colors.blueGrey,
        onPick: (p) async {
          await _db.collection('bowlingFigures').add({
            'inningsId': innings.id, 'fixtureId': innings.fixtureId,
            'tournamentId': innings.tournamentId,
            'playerId': p.id, 'playerName': p.name, 'teamId': innings.bowlingTeamId,
            'overs': 0, 'balls': 0, 'maidens': 0, 'runs': 0, 'wickets': 0,
            'wides': 0, 'noBalls': 0, 'bowlingOrder': bowling.length + 1,
          });
        },
      ),
    );
  }
}

class _BowlColHeader extends StatelessWidget {
  const _BowlColHeader();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF8F9FA),
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        child: Row(
          children: const [
            Expanded(flex: 10, child: Text('BOWLER', style: _colHeadStyle)),
            _ColH('O'),
            _ColH('M'),
            _ColH('R'),
            _ColH('W'),
            _ColH('Econ'),
          ],
        ),
      );
}

class _BowlRow extends StatelessWidget {
  final BowlingFigure figure;
  final CricketInnings innings;
  final bool canScore;
  const _BowlRow({required this.figure, required this.innings, required this.canScore});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: canScore
            ? () => showDialog(
                  context: context,
                  builder: (_) =>
                      _BowlingEditDialog(figure: figure, innings: innings),
                )
            : null,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(
                  figure.playerName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: _kTextPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ColV(figure.oversDisplay),
              _ColV('${figure.maidens}'),
              _ColV('${figure.runs}'),
              _ColV('${figure.wickets}', bold: figure.wickets > 0,
                  color: figure.wickets > 0 ? _kRed : null),
              _ColV(figure.economy.toStringAsFixed(2)),
            ],
          ),
        ),
      );
}

// ─── Pick Player Bottom Sheet ─────────────────────────────────────────────────
class _PickPlayerSheet extends StatelessWidget {
  final String title;
  final List<TournamentPlayer> players;
  final Color color;
  final Future<void> Function(TournamentPlayer) onPick;

  const _PickPlayerSheet({
    required this.title, required this.players,
    required this.color, required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: players.length,
            itemBuilder: (_, i) {
              final p = players[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(30),
                  child: Text(p.name[0].toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: p.jerseyNumber != null
                    ? Text('#${p.jerseyNumber}')
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await onPick(p);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _CardSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _CardSectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
        ),
        child: Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    letterSpacing: 1.2, color: _kTextSecondary)),
            const Spacer(),
            if (action != null) action!,
          ],
        ),
      );
}

class _GreenTextBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GreenTextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: _kGreenLight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
}

const _colHeadStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
    color: _kTextSecondary, letterSpacing: 0.3);

class _ColH extends StatelessWidget {
  final String t;
  const _ColH(this.t);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        child: Text(t,
            textAlign: TextAlign.center,
            style: _colHeadStyle),
      );
}

class _ColV extends StatelessWidget {
  final String t;
  final bool bold;
  final Color? color;
  const _ColV(this.t, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? _kTextPrimary)),
      );
}

class _ErrorScaffold extends StatelessWidget {
  final String error;
  const _ErrorScaffold({required this.error});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scorecard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MATCH SETUP SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class _MatchSetupScreen extends ConsumerStatefulWidget {
  final Fixture fixture;
  final Tournament tournament;
  final bool canScore;
  const _MatchSetupScreen({required this.fixture, required this.tournament, required this.canScore});

  @override
  ConsumerState<_MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<_MatchSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final Set<String> _homeXI = {}, _awayXI = {};
  String? _tossWinnerId, _tossWinnerName;
  String _tossElected = 'bat';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _homeXI.addAll(widget.fixture.homeXI);
    _awayXI.addAll(widget.fixture.awayXI);
    _tossWinnerId = widget.fixture.tossWinnerId;
    _tossWinnerName = widget.fixture.tossWinnerName;
    _tossElected = widget.fixture.tossElected ?? 'bat';
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_tossWinnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select toss winner')));
      return;
    }
    if (_homeXI.isEmpty || _awayXI.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least 1 player per team')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(firestoreServiceProvider).saveMatchSetup(
        tournamentId: widget.tournament.id,
        fixtureId: widget.fixture.id,
        homeXI: _homeXI.toList(),
        awayXI: _awayXI.toList(),
        tossWinnerId: _tossWinnerId!,
        tossWinnerName: _tossWinnerName!,
        tossElected: _tossElected,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers =
        ref.watch(tournamentPlayersProvider(widget.tournament.id)).valueOrNull ?? [];
    final allTeams =
        ref.watch(teamsProvider(widget.tournament.id)).valueOrNull ?? [];

    // Use team's playerIds list (set via team edit dialog) as the source of truth.
    // p.teamId may not be set if players were added via the team checkbox flow.
    final homeTeam = allTeams.where((t) => t.id == widget.fixture.homeTeamId).firstOrNull;
    final awayTeam = allTeams.where((t) => t.id == widget.fixture.awayTeamId).firstOrNull;

    final homePool = homeTeam != null
        ? allPlayers.where((p) => homeTeam.playerIds.contains(p.id) || p.teamId == widget.fixture.homeTeamId).toList()
        : allPlayers.where((p) => p.teamId == widget.fixture.homeTeamId).toList();
    final awayPool = awayTeam != null
        ? allPlayers.where((p) => awayTeam.playerIds.contains(p.id) || p.teamId == widget.fixture.awayTeamId).toList()
        : allPlayers.where((p) => p.teamId == widget.fixture.awayTeamId).toList();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.fixture.homeTeamName} vs ${widget.fixture.awayTeamName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Text('Match Setup', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: '🪙  Toss'),
            Tab(text: widget.fixture.homeTeamName),
            Tab(text: widget.fixture.awayTeamName),
          ],
        ),
      ),
      body: widget.canScore
          ? TabBarView(
              controller: _tab,
              children: [
                _TossTab(
                  fixture: widget.fixture,
                  tossWinnerId: _tossWinnerId,
                  tossElected: _tossElected,
                  onWinner: (id, name) =>
                      setState(() { _tossWinnerId = id; _tossWinnerName = name; }),
                  onElected: (v) => setState(() => _tossElected = v),
                ),
                _XITab(
                  teamName: widget.fixture.homeTeamName,
                  players: homePool,
                  selected: _homeXI,
                  onChanged: (id, v) =>
                      setState(() => v ? _homeXI.add(id) : _homeXI.remove(id)),
                ),
                _XITab(
                  teamName: widget.fixture.awayTeamName,
                  players: awayPool,
                  selected: _awayXI,
                  onChanged: (id, v) =>
                      setState(() => v ? _awayXI.add(id) : _awayXI.remove(id)),
                ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: _kTextLight),
                    SizedBox(height: 12),
                    Text('Match setup pending',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('The scorekeeper will set playing XI and toss.',
                        style: TextStyle(color: _kTextSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: widget.canScore
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _kGreenLight,
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Confirm Setup  ·  '
                          '${_homeXI.length} + ${_awayXI.length} players',
                          style: const TextStyle(fontSize: 15)),
                ),
              ),
            )
          : null,
    );
  }
}

class _TossTab extends StatelessWidget {
  final Fixture fixture;
  final String? tossWinnerId, tossElected;
  final void Function(String id, String name) onWinner;
  final void Function(String) onElected;
  const _TossTab({required this.fixture, required this.tossWinnerId,
      required this.tossElected, required this.onWinner, required this.onElected});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Who won the toss?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kTextPrimary)),
            const SizedBox(height: 16),
            _TossTeamCard(
              teamName: fixture.homeTeamName,
              selected: tossWinnerId == fixture.homeTeamId,
              onTap: () => onWinner(fixture.homeTeamId, fixture.homeTeamName),
            ),
            const SizedBox(height: 12),
            _TossTeamCard(
              teamName: fixture.awayTeamName,
              selected: tossWinnerId == fixture.awayTeamId,
              onTap: () => onWinner(fixture.awayTeamId, fixture.awayTeamName),
            ),
            if (tossWinnerId != null) ...[
              const SizedBox(height: 28),
              Text(
                '${tossWinnerId == fixture.homeTeamId ? fixture.homeTeamName : fixture.awayTeamName} elected to…',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kTextPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _ElectCard(icon: '🏏', label: 'Bat First',
                      selected: tossElected == 'bat', onTap: () => onElected('bat'))),
                  const SizedBox(width: 12),
                  Expanded(child: _ElectCard(icon: '🎳', label: 'Bowl First',
                      selected: tossElected == 'field', onTap: () => onElected('field'))),
                ],
              ),
            ],
          ],
        ),
      );
}

class _TossTeamCard extends StatelessWidget {
  final String teamName;
  final bool selected;
  final VoidCallback onTap;
  const _TossTeamCard({required this.teamName, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? _kGreenLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? _kGreenLight : Colors.grey.shade300, width: 2),
            boxShadow: selected
                ? [BoxShadow(color: _kGreenLight.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: selected
                    ? Colors.white.withAlpha(50) : _kGreenBg,
                child: Text(teamName[0].toUpperCase(),
                    style: TextStyle(
                        color: selected ? Colors.white : _kGreenLight,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(teamName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15,
                        color: selected ? Colors.white : _kTextPrimary)),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white),
            ],
          ),
        ),
      );
}

class _ElectCard extends StatelessWidget {
  final String icon, label;
  final bool selected;
  final VoidCallback onTap;
  const _ElectCard({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: selected ? _kGreenLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? _kGreenLight : Colors.grey.shade300, width: 2),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : _kTextPrimary)),
            ],
          ),
        ),
      );
}

class _XITab extends StatelessWidget {
  final String teamName;
  final List<TournamentPlayer> players;
  final Set<String> selected;
  final void Function(String, bool) onChanged;
  const _XITab({required this.teamName, required this.players,
      required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text('${selected.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _kGreenLight)),
              const Text('  ·  tap to select playing XI',
                  style: TextStyle(color: _kTextSecondary, fontSize: 13)),
              const Spacer(),
              Text('of ${players.length}', style: const TextStyle(color: _kTextLight, fontSize: 12)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined, size: 48, color: _kTextLight),
                      const SizedBox(height: 12),
                      Text('No players in $teamName',
                          style: const TextStyle(color: _kTextSecondary)),
                      const SizedBox(height: 4),
                      const Text('Add players from the Players tab first.',
                          style: TextStyle(color: _kTextLight, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (_, i) {
                    final p = players[i];
                    final isSelected = selected.contains(p.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (v) => onChanged(p.id, v ?? false),
                      activeColor: _kGreenLight,
                      checkColor: Colors.white,
                      tileColor: isSelected ? const Color(0xFFF1F8E9) : Colors.white,
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: p.phone.isNotEmpty ? Text(p.phone) : null,
                      secondary: p.jerseyNumber != null
                          ? CircleAvatar(
                              radius: 16,
                              backgroundColor: isSelected ? _kGreenBg : const Color(0xFFF5F5F5),
                              child: Text('#${p.jerseyNumber}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? _kGreenLight : _kTextSecondary)),
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDIT DIALOGS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Innings Edit ─────────────────────────────────────────────────────────────
class _InningsEditDialog extends StatefulWidget {
  final CricketInnings innings;
  const _InningsEditDialog({required this.innings});

  @override
  State<_InningsEditDialog> createState() => _InningsEditDialogState();
}

class _InningsEditDialogState extends State<_InningsEditDialog> {
  late TextEditingController _runs, _wkts, _ovs, _bls, _wd, _nb, _by, _lb;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.innings;
    _runs = TextEditingController(text: '${i.totalRuns}');
    _wkts = TextEditingController(text: '${i.totalWickets}');
    _ovs  = TextEditingController(text: '${i.overs}');
    _bls  = TextEditingController(text: '${i.balls}');
    _wd   = TextEditingController(text: '${i.wides}');
    _nb   = TextEditingController(text: '${i.noBalls}');
    _by   = TextEditingController(text: '${i.byes}');
    _lb   = TextEditingController(text: '${i.legByes}');
  }

  @override
  void dispose() {
    for (final c in [_runs, _wkts, _ovs, _bls, _wd, _nb, _by, _lb]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _db.collection('cricketInnings').doc(widget.innings.id).update({
        'totalRuns': int.tryParse(_runs.text) ?? 0,
        'totalWickets': int.tryParse(_wkts.text) ?? 0,
        'overs': int.tryParse(_ovs.text) ?? 0,
        'balls': int.tryParse(_bls.text) ?? 0,
        'wides': int.tryParse(_wd.text) ?? 0,
        'noBalls': int.tryParse(_nb.text) ?? 0,
        'byes': int.tryParse(_by.text) ?? 0,
        'legByes': int.tryParse(_lb.text) ?? 0,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Innings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _NF('Runs', _runs)),
              const SizedBox(width: 8),
              Expanded(child: _NF('Wickets', _wkts)),
              const SizedBox(width: 8),
              Expanded(child: _NF('Overs', _ovs)),
              const SizedBox(width: 8),
              Expanded(child: _NF('Balls', _bls)),
            ]),
            const SizedBox(height: 14),
            const Text('Extras', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _NF('Wides', _wd)),
              const SizedBox(width: 8),
              Expanded(child: _NF('No Balls', _nb)),
              const SizedBox(width: 8),
              Expanded(child: _NF('Byes', _by)),
              const SizedBox(width: 8),
              Expanded(child: _NF('Leg Byes', _lb)),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kGreenLight),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Batting Edit ─────────────────────────────────────────────────────────────
class _BattingEditDialog extends StatefulWidget {
  final BattingScore score;
  final CricketInnings innings;
  final List<TournamentPlayer> bowlingPlayers;
  const _BattingEditDialog({required this.score, required this.innings,
      required this.bowlingPlayers});

  @override
  State<_BattingEditDialog> createState() => _BattingEditDialogState();
}

class _BattingEditDialogState extends State<_BattingEditDialog> {
  late TextEditingController _runs, _balls, _fours, _sixes;
  late String _dismissal;
  String? _bowlerId, _bowlerName, _fielderId, _fielderName;
  bool _saving = false;

  static const _modes = [
    ('batting', 'Still Batting'), ('notOut', 'Not Out'),
    ('bowled', 'Bowled'), ('caught', 'Caught'), ('lbw', 'LBW'),
    ('runOut', 'Run Out'), ('stumped', 'Stumped'),
    ('hitWicket', 'Hit Wicket'), ('retired', 'Retired'),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.score;
    _runs   = TextEditingController(text: '${s.runs}');
    _balls  = TextEditingController(text: '${s.balls}');
    _fours  = TextEditingController(text: '${s.fours}');
    _sixes  = TextEditingController(text: '${s.sixes}');
    _dismissal = s.dismissal;
    _bowlerId   = s.bowlerId.isEmpty ? null : s.bowlerId;
    _bowlerName = s.bowlerName.isEmpty ? null : s.bowlerName;
    _fielderId   = s.fielderId.isEmpty ? null : s.fielderId;
    _fielderName = s.fielderName.isEmpty ? null : s.fielderName;
  }

  @override
  void dispose() {
    for (final c in [_runs, _balls, _fours, _sixes]) c.dispose();
    super.dispose();
  }

  bool get _needsBowler => ['bowled', 'caught', 'lbw', 'stumped', 'hitWicket'].contains(_dismissal);
  bool get _needsFielder => ['caught', 'runOut', 'stumped'].contains(_dismissal);

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _db.collection('battingScores').doc(widget.score.id).update({
        'runs': int.tryParse(_runs.text) ?? 0,
        'balls': int.tryParse(_balls.text) ?? 0,
        'fours': int.tryParse(_fours.text) ?? 0,
        'sixes': int.tryParse(_sixes.text) ?? 0,
        'dismissal': _dismissal,
        'bowlerId': _bowlerId ?? '', 'bowlerName': _bowlerName ?? '',
        'fielderId': _fielderId ?? '', 'fielderName': _fielderName ?? '',
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.score.playerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(child: _NF('Runs', _runs)),
              const SizedBox(width: 6),
              Expanded(child: _NF('Balls', _balls)),
              const SizedBox(width: 6),
              Expanded(child: _NF('4s', _fours)),
              const SizedBox(width: 6),
              Expanded(child: _NF('6s', _sixes)),
            ]),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _dismissal,
              decoration: const InputDecoration(
                  labelText: 'How Out', isDense: true, border: OutlineInputBorder()),
              items: _modes.map((m) =>
                  DropdownMenuItem(value: m.$1, child: Text(m.$2))).toList(),
              onChanged: (v) => setState(() {
                _dismissal = v!;
                if (!_needsBowler) { _bowlerId = null; _bowlerName = null; }
                if (!_needsFielder) { _fielderId = null; _fielderName = null; }
              }),
            ),
            if (_needsBowler) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<TournamentPlayer>(
                decoration: const InputDecoration(
                    labelText: 'Bowler', isDense: true, border: OutlineInputBorder()),
                value: widget.bowlingPlayers.where((p) => p.id == _bowlerId).firstOrNull,
                items: widget.bowlingPlayers
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (p) => setState(() { _bowlerId = p?.id; _bowlerName = p?.name; }),
              ),
            ],
            if (_needsFielder) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<TournamentPlayer>(
                decoration: InputDecoration(
                    labelText: _dismissal == 'runOut' ? 'Fielder' : 'Catcher / Fielder',
                    isDense: true, border: const OutlineInputBorder()),
                value: widget.bowlingPlayers.where((p) => p.id == _fielderId).firstOrNull,
                items: widget.bowlingPlayers
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (p) => setState(() { _fielderId = p?.id; _fielderName = p?.name; }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kGreenLight),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Bowling Edit ─────────────────────────────────────────────────────────────
class _BowlingEditDialog extends StatefulWidget {
  final BowlingFigure figure;
  final CricketInnings innings;
  const _BowlingEditDialog({required this.figure, required this.innings});

  @override
  State<_BowlingEditDialog> createState() => _BowlingEditDialogState();
}

class _BowlingEditDialogState extends State<_BowlingEditDialog> {
  late TextEditingController _ovs, _bls, _mai, _rns, _wkt, _wd, _nb;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.figure;
    _ovs = TextEditingController(text: '${f.overs}');
    _bls = TextEditingController(text: '${f.balls}');
    _mai = TextEditingController(text: '${f.maidens}');
    _rns = TextEditingController(text: '${f.runs}');
    _wkt = TextEditingController(text: '${f.wickets}');
    _wd  = TextEditingController(text: '${f.wides}');
    _nb  = TextEditingController(text: '${f.noBalls}');
  }

  @override
  void dispose() {
    for (final c in [_ovs, _bls, _mai, _rns, _wkt, _wd, _nb]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _db.collection('bowlingFigures').doc(widget.figure.id).update({
        'overs': int.tryParse(_ovs.text) ?? 0,
        'balls': int.tryParse(_bls.text) ?? 0,
        'maidens': int.tryParse(_mai.text) ?? 0,
        'runs': int.tryParse(_rns.text) ?? 0,
        'wickets': int.tryParse(_wkt.text) ?? 0,
        'wides': int.tryParse(_wd.text) ?? 0,
        'noBalls': int.tryParse(_nb.text) ?? 0,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.figure.playerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(child: _NF('Overs', _ovs)),
            const SizedBox(width: 6),
            Expanded(child: _NF('Balls', _bls)),
            const SizedBox(width: 6),
            Expanded(child: _NF('Maidens', _mai)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _NF('Runs', _rns)),
            const SizedBox(width: 6),
            Expanded(child: _NF('Wickets', _wkt)),
            const SizedBox(width: 6),
            Expanded(child: _NF('Wides', _wd)),
            const SizedBox(width: 6),
            Expanded(child: _NF('No Balls', _nb)),
          ]),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kGreenLight),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Number field helper ──────────────────────────────────────────────────────
class _NF extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _NF(this.label, this.ctrl);

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        ),
      );
}
