import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

final _db = FirebaseFirestore.instance;

// ─── Colour constants (reuse scorecard palette) ───────────────────────────────
const _kGreen      = Color(0xFF1B5E20);
const _kGreenLight = Color(0xFF2E7D32);
const _kRed        = Color(0xFFC62828);
const _kRedBg      = Color(0xFFFFEBEE);
const _kAmber      = Color(0xFFE65100);
const _kBg         = Color(0xFFF5F5F5);

// ─── Helper ───────────────────────────────────────────────────────────────────
class _BatsmanInfo {
  final String id;       // batting score doc ID
  final String playerId; // TournamentPlayer doc ID — used for filtering
  final String name;
  int runs, balls, fours, sixes;
  String dismissal;
  _BatsmanInfo({
    required this.id, required this.playerId, required this.name,
    this.runs = 0, this.balls = 0, this.fours = 0, this.sixes = 0,
    this.dismissal = 'batting',
  });
  bool get isBatting => dismissal == 'batting';
  double get sr => balls == 0 ? 0 : runs / balls * 100;
}

class _BowlerInfo {
  final String id;       // bowling figure doc ID
  final String playerId; // TournamentPlayer doc ID
  final String name;
  int overs, balls, runs, wickets, wides, noBalls;
  _BowlerInfo({
    required this.id, required this.playerId, required this.name,
    this.overs = 0, this.balls = 0, this.runs = 0, this.wickets = 0,
    this.wides = 0, this.noBalls = 0,
  });
  String get figures => '$wickets/$runs  $overs.$balls';
}

// ═══════════════════════════════════════════════════════════════════════════════
// LIVE SCORING SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class CricketLiveScoringScreen extends ConsumerStatefulWidget {
  final String inningsId;
  final String tournamentId;
  final String fixtureId;
  final int? maxOvers;
  final int? playersPerSide;
  final int? maxOversPerBowler;

  const CricketLiveScoringScreen({
    super.key,
    required this.inningsId,
    required this.tournamentId,
    required this.fixtureId,
    this.maxOvers,
    this.playersPerSide,
    this.maxOversPerBowler,
  });

  @override
  ConsumerState<CricketLiveScoringScreen> createState() =>
      _CricketLiveScoringScreenState();
}

class _CricketLiveScoringScreenState
    extends ConsumerState<CricketLiveScoringScreen> {

  // ── Live session state ──────────────────────────────────────────────────────
  String? _strikerId;      // batting score doc ID
  String? _nonStrikerId;   // batting score doc ID
  String? _bowlerId;       // bowling figure doc ID
  final List<String> _overBalls = [];   // display: '·','1','4','Wd','W','6'
  int _legalBalls = 0;     // legal deliveries this over
  bool _saving = false;

  // Loaded from DB so we can do quick in-memory increments
  Map<String, _BatsmanInfo> _batters = {};   // docId → info
  Map<String, _BowlerInfo>  _bowlers = {};   // docId → info

  // Innings snapshot
  int _totalRuns = 0, _totalWickets = 0, _overs = 0, _ovBalls = 0;
  int _wides = 0, _noBalls = 0, _byes = 0, _legByes = 0;

  String _battingTeamName = '';
  String _bowlingTeamName = '';
  String _battingTeamId = '';
  String _bowlingTeamId = '';
  int _inningsNumber = 1;
  bool _isCompleted = false;

  // All players in playing XI
  List<TournamentPlayer> _battingXIPlayers = [];
  List<TournamentPlayer> _bowlingXIPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  // ── Initial load ────────────────────────────────────────────────────────────
  Future<void> _loadInitialState() async {
    // Load innings doc
    final inningsDoc =
        await _db.collection('cricketInnings').doc(widget.inningsId).get();
    if (!inningsDoc.exists || !mounted) return;
    final d = inningsDoc.data()!;

    setState(() {
      _totalRuns    = d['totalRuns'] ?? 0;
      _totalWickets = d['totalWickets'] ?? 0;
      _overs        = d['overs'] ?? 0;
      _ovBalls      = d['balls'] ?? 0;
      _wides        = d['wides'] ?? 0;
      _noBalls      = d['noBalls'] ?? 0;
      _byes         = d['byes'] ?? 0;
      _legByes      = d['legByes'] ?? 0;
      _battingTeamName  = d['battingTeamName'] ?? '';
      _bowlingTeamName  = d['bowlingTeamName'] ?? '';
      _battingTeamId    = d['battingTeamId'] ?? '';
      _bowlingTeamId    = d['bowlingTeamId'] ?? '';
      _inningsNumber    = d['inningsNumber'] ?? 1;
      _isCompleted      = d['isCompleted'] ?? false;
      // Restore last known striker if saved
      _strikerId    = d['strikerId'];
      _nonStrikerId = d['nonStrikerId'];
      _bowlerId     = d['currentBowlerId'];
      _legalBalls   = d['legalBallsInOver'] ?? 0;
      final saved = List<String>.from(d['currentOverBalls'] ?? []);
      _overBalls
        ..clear()
        ..addAll(saved);
    });

    // Load batting scores
    final batSnap = await _db.collection('battingScores')
        .where('inningsId', isEqualTo: widget.inningsId).get();
    final Map<String, _BatsmanInfo> bmap = {};
    for (final doc in batSnap.docs) {
      final dd = doc.data();
      bmap[doc.id] = _BatsmanInfo(
        id: doc.id, playerId: dd['playerId'] ?? '', name: dd['playerName'] ?? '',
        runs: dd['runs'] ?? 0, balls: dd['balls'] ?? 0,
        fours: dd['fours'] ?? 0, sixes: dd['sixes'] ?? 0,
        dismissal: dd['dismissal'] ?? 'batting',
      );
    }
    if (mounted) setState(() => _batters = bmap);

    // Load bowling figures
    final bowlSnap = await _db.collection('bowlingFigures')
        .where('inningsId', isEqualTo: widget.inningsId).get();
    final Map<String, _BowlerInfo> bowlMap = {};
    for (final doc in bowlSnap.docs) {
      final dd = doc.data();
      bowlMap[doc.id] = _BowlerInfo(
        id: doc.id, playerId: dd['playerId'] ?? '', name: dd['playerName'] ?? '',
        overs: dd['overs'] ?? 0, balls: dd['balls'] ?? 0,
        runs: dd['runs'] ?? 0, wickets: dd['wickets'] ?? 0,
        wides: dd['wides'] ?? 0, noBalls: dd['noBalls'] ?? 0,
      );
    }
    if (mounted) setState(() => _bowlers = bowlMap);
  }

  // ── Firestore helpers ───────────────────────────────────────────────────────
  Future<void> _persistInnings() async {
    await _db.collection('cricketInnings').doc(widget.inningsId).update({
      'totalRuns': _totalRuns,
      'totalWickets': _totalWickets,
      'overs': _overs,
      'balls': _ovBalls,
      'wides': _wides,
      'noBalls': _noBalls,
      'byes': _byes,
      'legByes': _legByes,
      // persist session state so screen survives navigation
      'strikerId': _strikerId,
      'nonStrikerId': _nonStrikerId,
      'currentBowlerId': _bowlerId,
      'legalBallsInOver': _legalBalls,
      'currentOverBalls': _overBalls,
    });
  }

  Future<void> _persistBatter(String docId) async {
    final b = _batters[docId];
    if (b == null) return;
    await _db.collection('battingScores').doc(docId).update({
      'runs': b.runs, 'balls': b.balls,
      'fours': b.fours, 'sixes': b.sixes,
      'dismissal': b.dismissal,
    });
  }

  Future<void> _persistBowler(String docId) async {
    final b = _bowlers[docId];
    if (b == null) return;
    await _db.collection('bowlingFigures').doc(docId).update({
      'overs': b.overs, 'balls': b.balls,
      'runs': b.runs, 'wickets': b.wickets,
      'wides': b.wides, 'noBalls': b.noBalls,
    });
  }

  // ── Core ball recording ─────────────────────────────────────────────────────
  Future<void> _recordDelivery({
    int runs = 0,
    bool wide = false,
    bool noBall = false,
    bool bye = false,
    bool legBye = false,
  }) async {
    if (_strikerId == null || _bowlerId == null) {
      _showNeedSetup();
      return;
    }
    setState(() => _saving = true);
    try {
      final bool isLegal = !wide && !noBall;
      final striker = _batters[_strikerId!];
      final bowler  = _bowlers[_bowlerId!];
      if (striker == null || bowler == null) return;

      // ── Update innings totals ─────────────────────────────────────
      _totalRuns += runs + (wide || noBall ? 1 : 0);
      if (bye)    _byes    += runs;
      if (legBye) _legByes += runs;
      if (wide)   _wides   += 1;
      if (noBall) _noBalls += 1;

      // ── Update batsman (not for wides) ────────────────────────────
      if (!wide) {
        if (!bye && !legBye) striker.runs += runs;
        striker.balls += 1;
        if (runs == 4 && !bye && !legBye) striker.fours += 1;
        if (runs == 6 && !bye && !legBye) striker.sixes += 1;
      }

      // ── Update bowler ─────────────────────────────────────────────
      bowler.runs += runs + (wide || noBall ? 1 : 0);
      if (wide)   bowler.wides   += 1;
      if (noBall) bowler.noBalls += 1;

      // ── Legal ball counting ───────────────────────────────────────
      if (isLegal) {
        _legalBalls += 1;
        bowler.balls += 1;
        if (bowler.balls >= 6) {
          bowler.overs += 1;
          bowler.balls = 0;
          _overs += 1;
          _ovBalls = 0;
        } else {
          _ovBalls = bowler.balls;
        }
      }

      // ── Over display ──────────────────────────────────────────────
      String label = wide ? 'Wd'
          : noBall ? 'Nb'
          : bye ? 'B${runs > 0 ? runs : ""}'
          : legBye ? 'Lb${runs > 0 ? runs : ""}'
          : runs == 0 ? '·' : '$runs';
      _overBalls.add(label);

      // ── Swap striker if odd runs (end of legal ball) ─────────────
      if (!wide && runs.isOdd) _swapStrike();

      // ── Persist ───────────────────────────────────────────────────
      await Future.wait([
        _persistInnings(),
        _persistBatter(_strikerId!),
        _persistBowler(_bowlerId!),
      ]);

      // ── Check innings completion ──────────────────────────────────
      if (_inningsIsComplete) {
        await _completeInnings();
        return;
      }

      // ── End of over ───────────────────────────────────────────────
      if (isLegal && _legalBalls >= 6) {
        _swapStrike(); // swap at end of over
        _legalBalls = 0;
        _overBalls.clear();
        await _persistInnings();
        if (mounted) _showPickBowler();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _inningsIsComplete {
    final maxW = (widget.playersPerSide ?? 11) - 1;
    final maxOv = widget.maxOvers;
    if (_totalWickets >= maxW) return true;
    if (maxOv != null && _overs >= maxOv) return true;
    return false;
  }

  Future<void> _completeInnings() async {
    setState(() => _isCompleted = true);
    await _db.collection('cricketInnings').doc(widget.inningsId).update({
      'isCompleted': true,
      'totalRuns': _totalRuns,
      'totalWickets': _totalWickets,
      'overs': _overs,
      'balls': _ovBalls,
    });
  }

  Future<void> _startNextInnings() async {
    // Create the next innings doc with teams swapped
    final ref = _db.collection('cricketInnings').doc();
    await ref.set({
      'fixtureId': widget.fixtureId,
      'tournamentId': widget.tournamentId,
      'battingTeamId': _bowlingTeamId,
      'battingTeamName': _bowlingTeamName,
      'bowlingTeamId': _battingTeamId,
      'bowlingTeamName': _battingTeamName,
      'inningsNumber': _inningsNumber + 1,
      'totalRuns': 0, 'totalWickets': 0,
      'overs': 0, 'balls': 0,
      'wides': 0, 'noBalls': 0, 'byes': 0, 'legByes': 0,
      'isCompleted': false,
    });
    if (!mounted) return;
    // Navigate to new innings scoring screen (replace current)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CricketLiveScoringScreen(
          inningsId: ref.id,
          tournamentId: widget.tournamentId,
          fixtureId: widget.fixtureId,
          maxOvers: widget.maxOvers,
          playersPerSide: widget.playersPerSide,
          maxOversPerBowler: widget.maxOversPerBowler,
        ),
      ),
    );
  }

  void _swapStrike() {
    final tmp = _strikerId;
    _strikerId = _nonStrikerId;
    _nonStrikerId = tmp;
  }

  // ── Wicket ─────────────────────────────────────────────────────────────────
  void _onWicket() {
    if (_strikerId == null || _bowlerId == null) {
      _showNeedSetup();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WicketSheet(
        striker: _batters[_strikerId!]!,
        bowler: _bowlers[_bowlerId!]!,
        bowlingPlayers: _bowlingXIPlayers,
        onConfirm: (dismissal, bowlerName, fielderName) =>
            _recordWicket(dismissal, bowlerName, fielderName),
      ),
    );
  }

  Future<void> _recordWicket(
      String dismissal, String bowlerName, String fielderName) async {
    setState(() => _saving = true);
    try {
      final striker = _batters[_strikerId!]!;
      final bowler  = _bowlers[_bowlerId!]!;

      // Update batsman dismissal
      striker.dismissal = dismissal;
      striker.balls += 1;
      _totalWickets += 1;
      bowler.wickets += 1;
      bowler.balls += 1;
      _legalBalls += 1;
      _overBalls.add('W');

      if (bowler.balls >= 6) {
        bowler.overs += 1; bowler.balls = 0;
        _overs += 1; _ovBalls = 0;
      } else {
        _ovBalls = bowler.balls;
      }

      // Persist dismissal
      await _db.collection('battingScores').doc(_strikerId!).update({
        'runs': striker.runs, 'balls': striker.balls,
        'dismissal': dismissal,
        'bowlerName': bowlerName, 'fielderName': fielderName,
      });
      await Future.wait([
        _persistInnings(),
        _persistBowler(_bowlerId!),
      ]);

      // Check if innings is over (all out)
      if (_inningsIsComplete) {
        await _completeInnings();
        return;
      }

      // Select next batsman
      if (mounted) _showPickNextBatter();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Bottom sheets ───────────────────────────────────────────────────────────
  void _showNeedSetup() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Select striker, non-striker, and bowler first.'),
    ));
    _showSetupSheet();
  }

  void _showSetupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SetupSheet(
        allBatters: _batters,
        allBowlers: _bowlers,
        battingPlayers: _battingXIPlayers,
        bowlingPlayers: _bowlingXIPlayers,
        strikerId: _strikerId,
        nonStrikerId: _nonStrikerId,
        bowlerId: _bowlerId,
        onConfirm: (s, ns, b) => setState(() {
          _strikerId = s;
          _nonStrikerId = ns;
          _bowlerId = b;
        }),
        addBatter: _addBatter,
        addBowler: _pickOrAddBowler,
      ),
    );
  }

  void _showPickNextBatter() {
    // Filter by playerId (TournamentPlayer ID), not the batting-score doc ID
    final appearedPlayerIds = _batters.values.map((b) => b.playerId).toSet();
    final yetToBat = _battingXIPlayers
        .where((p) => !appearedPlayerIds.contains(p.id))
        .toList();
    if (yetToBat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All batsmen have batted!')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickPlayerSheet(
        title: 'Next Batsman',
        subtitle: 'Who is coming in?',
        players: yetToBat,
        color: _kGreenLight,
        onPick: (p) => _addBatter(p),
      ),
    );
  }

  void _showPickBowler() {
    // Exclude the just-finished bowler (can't bowl consecutive overs)
    final currentBowlerPlayerId = _bowlerId != null
        ? _bowlers[_bowlerId!]?.playerId : null;
    final available = _bowlingXIPlayers.where((p) {
      if (p.id == currentBowlerPlayerId) return false;
      if (widget.maxOversPerBowler != null && widget.maxOversPerBowler! < 999) {
        final bowlerFig = _bowlers.values
            .where((b) => b.playerId == p.id)
            .firstOrNull;
        if (bowlerFig != null && bowlerFig.overs >= widget.maxOversPerBowler!) {
          return false;
        }
      }
      return true;
    }).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickPlayerSheet(
        title: 'Next Bowler',
        subtitle: 'Who is bowling the next over?',
        players: available,
        color: Colors.indigo,
        onPick: (p) => _pickOrAddBowler(p),
      ),
    );
  }

  Future<void> _addBatter(TournamentPlayer p) async {
    // Find or create batting score doc
    final existing = _batters.values
        .where((b) => b.id == p.id)
        .toList();
    if (existing.isNotEmpty) {
      setState(() => _strikerId = existing.first.id);
      return;
    }
    final ref = _db.collection('battingScores').doc();
    final pos = _batters.length + 1;
    await ref.set({
      'inningsId': widget.inningsId, 'fixtureId': widget.fixtureId,
      'tournamentId': widget.tournamentId,
      'playerId': p.id, 'playerName': p.name,
      'teamId': '', 'runs': 0, 'balls': 0, 'fours': 0, 'sixes': 0,
      'dismissal': 'batting',
      'bowlerId': '', 'bowlerName': '', 'fielderId': '', 'fielderName': '',
      'battingPosition': pos,
    });
    final info = _BatsmanInfo(id: ref.id, playerId: p.id, name: p.name);
    if (mounted) setState(() {
      _batters[ref.id] = info;
      _strikerId = ref.id;
    });
  }

  Future<void> _pickOrAddBowler(TournamentPlayer p) async {
    // Find existing bowling figure for this player (match by playerId)
    final existing = _bowlers.values
        .where((b) => b.playerId == p.id)
        .toList();
    if (existing.isNotEmpty) {
      setState(() => _bowlerId = existing.first.id);
      return;
    }
    final ref = _db.collection('bowlingFigures').doc();
    await ref.set({
      'inningsId': widget.inningsId, 'fixtureId': widget.fixtureId,
      'tournamentId': widget.tournamentId,
      'playerId': p.id, 'playerName': p.name,
      'teamId': '', 'overs': 0, 'balls': 0, 'maidens': 0,
      'runs': 0, 'wickets': 0, 'wides': 0, 'noBalls': 0,
      'bowlingOrder': _bowlers.length + 1,
    });
    final info = _BowlerInfo(id: ref.id, playerId: p.id, name: p.name);
    if (mounted) setState(() {
      _bowlers[ref.id] = info;
      _bowlerId = ref.id;
    });
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────
  void _loadXIPlayers() {
    final allPlayers =
        ref.read(tournamentPlayersProvider(widget.tournamentId)).valueOrNull ?? [];
    final fixture = ref.read(fixturesProvider(widget.tournamentId)).valueOrNull
        ?.where((f) => f.id == widget.fixtureId).firstOrNull;
    if (fixture == null) return;
    // Determine batting/bowling XI based on innings doc's batting team
    _db.collection('cricketInnings').doc(widget.inningsId)
        .get().then((doc) {
      if (!doc.exists) return;
      final battingTeamId = doc.data()!['battingTeamId'] as String? ?? '';
      final isBattingHome = battingTeamId == fixture.homeTeamId;
      setState(() {
        _battingXIPlayers = allPlayers
            .where((p) => isBattingHome
                ? fixture.homeXI.contains(p.id)
                : fixture.awayXI.contains(p.id))
            .toList();
        _bowlingXIPlayers = allPlayers
            .where((p) => isBattingHome
                ? fixture.awayXI.contains(p.id)
                : fixture.homeXI.contains(p.id))
            .toList();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadXIPlayers();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final striker    = _strikerId    != null ? _batters[_strikerId!]    : null;
    final nonStriker = _nonStrikerId != null ? _batters[_nonStrikerId!] : null;
    final bowler     = _bowlerId     != null ? _bowlers[_bowlerId!]     : null;

    final overDisp = _overs.toString() +
        (_ovBalls > 0 ? '.$_ovBalls' : '.0');

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
              '$_battingTeamName  $_totalRuns/$_totalWickets',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text('($overDisp Ov)  ·  Live Scoring',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Change Players',
            onPressed: _showSetupSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Innings complete banner ───────────────────────────────────
          if (_isCompleted)
            _InningsCompleteBanner(
              teamName: _battingTeamName,
              runs: _totalRuns,
              wickets: _totalWickets,
              overs: _overs,
              balls: _ovBalls,
              inningsNumber: _inningsNumber,
              onStartNext: _startNextInnings,
              onClose: () => Navigator.pop(context),
            ),

          // ── Players panel ─────────────────────────────────────────────
          _PlayersPanel(
            striker: striker,
            nonStriker: nonStriker,
            bowler: bowler,
            onSwapStrike: () => setState(_swapStrike),
            onSetup: _showSetupSheet,
          ),

          // ── This over ─────────────────────────────────────────────────
          _OverDisplay(balls: _overBalls, legalBalls: _legalBalls),

          const SizedBox(height: 8),

          // ── Run buttons ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AbsorbPointer(
                absorbing: _isCompleted || _saving,
                child: Opacity(
                  opacity: _isCompleted ? 0.35 : 1.0,
                  child: Column(
                    children: [
                      // Row 1: 0 1 2 3
                      Expanded(
                        child: Row(
                          children: [
                            _RunBtn(label: '0', sublabel: 'DOT', color: Colors.grey.shade700,
                                onTap: () => _recordDelivery(runs: 0)),
                            const SizedBox(width: 10),
                            _RunBtn(label: '1', color: Colors.blueGrey.shade700,
                                onTap: () => _recordDelivery(runs: 1)),
                            const SizedBox(width: 10),
                            _RunBtn(label: '2', color: Colors.blueGrey.shade700,
                                onTap: () => _recordDelivery(runs: 2)),
                            const SizedBox(width: 10),
                            _RunBtn(label: '3', color: Colors.blueGrey.shade600,
                                onTap: () => _recordDelivery(runs: 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Row 2: 4  6
                      Expanded(
                        child: Row(
                          children: [
                            _RunBtn(label: '4', sublabel: 'FOUR',
                                color: _kGreenLight, big: true,
                                onTap: () => _recordDelivery(runs: 4)),
                            const SizedBox(width: 10),
                            _RunBtn(label: '6', sublabel: 'SIX',
                                color: _kGreen, big: true,
                                onTap: () => _recordDelivery(runs: 6)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Row 3: Extras
                      Row(
                        children: [
                          _ExtraBtn(label: 'WIDE', sublabel: '+1',
                              color: _kAmber,
                              onTap: () => _recordDelivery(wide: true)),
                          const SizedBox(width: 8),
                          _ExtraBtn(label: 'NO BALL', sublabel: '+1',
                              color: _kAmber,
                              onTap: () => _recordDelivery(noBall: true)),
                          const SizedBox(width: 8),
                          _ExtraBtn(label: 'BYE', color: Colors.blueGrey,
                              onTap: () => _showByeDialog(bye: true)),
                          const SizedBox(width: 8),
                          _ExtraBtn(label: 'LEG BYE', color: Colors.blueGrey,
                              onTap: () => _showByeDialog(bye: false)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Row 4: WICKET
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          icon: const Text('🏏', style: TextStyle(fontSize: 22)),
                          label: const Text('WICKET',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                          onPressed: _onWicket,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showByeDialog({required bool bye}) {
    showDialog(
      context: context,
      builder: (_) => _ByeRunDialog(
        title: bye ? 'Bye Runs' : 'Leg Bye Runs',
        onPick: (runs) => _recordDelivery(
          runs: runs, bye: bye, legBye: !bye),
      ),
    );
  }
}

// ─── Players panel ────────────────────────────────────────────────────────────
class _PlayersPanel extends StatelessWidget {
  final _BatsmanInfo? striker, nonStriker;
  final _BowlerInfo?  bowler;
  final VoidCallback onSwapStrike;
  final VoidCallback onSetup;
  const _PlayersPanel({
    required this.striker, required this.nonStriker, required this.bowler,
    required this.onSwapStrike, required this.onSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Batting
          Row(
            children: [
              const Icon(Icons.sports_cricket, size: 16, color: _kGreenLight),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BatterRow(batter: striker,    isStriker: true,  onSwap: onSwapStrike),
                    const SizedBox(height: 4),
                    _BatterRow(batter: nonStriker, isStriker: false, onSwap: onSwapStrike),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSetup,
                child: const Icon(Icons.swap_vert, color: _kGreenLight, size: 22),
              ),
            ],
          ),
          const Divider(height: 14),
          // Bowling
          Row(
            children: [
              const Icon(Icons.album, size: 16, color: Colors.indigo),
              const SizedBox(width: 6),
              Expanded(
                child: bowler == null
                    ? GestureDetector(
                        onTap: onSetup,
                        child: const Text('Tap ⚙ to select bowler',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(bowler!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            '${bowler!.overs}.${bowler!.balls}-${bowler!.runs}-${bowler!.wickets}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.indigo,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatterRow extends StatelessWidget {
  final _BatsmanInfo? batter;
  final bool isStriker;
  final VoidCallback onSwap;
  const _BatterRow({required this.batter, required this.isStriker, required this.onSwap});

  @override
  Widget build(BuildContext context) {
    if (batter == null) {
      return Text(
        isStriker ? '★ Select striker…' : '  Select non-striker…',
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      );
    }
    return GestureDetector(
      onTap: onSwap,
      child: Row(
        children: [
          Text(
            isStriker ? '★ ' : '   ',
            style: TextStyle(
              color: isStriker ? _kGreenLight : Colors.transparent,
              fontWeight: FontWeight.bold, fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              batter!.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isStriker ? _kGreenLight : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${batter!.runs}(${batter!.balls})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
              color: isStriker ? _kGreenLight : Colors.grey,
            ),
          ),
          if (batter!.fours > 0 || batter!.sixes > 0) ...[
            const SizedBox(width: 6),
            Text('${batter!.fours}×4  ${batter!.sixes}×6',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}

// ─── Over display ─────────────────────────────────────────────────────────────
class _OverDisplay extends StatelessWidget {
  final List<String> balls;
  final int legalBalls;
  const _OverDisplay({required this.balls, required this.legalBalls});

  Color _ballColor(String b) {
    if (b == 'W') return _kRed;
    if (b == '4') return _kGreenLight;
    if (b == '6') return _kGreen;
    if (b.startsWith('Wd') || b.startsWith('Nb')) return _kAmber;
    if (b.startsWith('B') || b.startsWith('Lb')) return Colors.blueGrey;
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('This over:',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          ...balls.map((b) => Container(
                margin: const EdgeInsets.only(right: 6),
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: _ballColor(b).withAlpha(b == 'W' ? 220 : 40),
                  shape: BoxShape.circle,
                  border: Border.all(color: _ballColor(b), width: 1.5),
                ),
                child: Center(
                  child: Text(b,
                      style: TextStyle(
                          fontSize: b.length > 2 ? 8 : 12,
                          fontWeight: FontWeight.bold,
                          color: _ballColor(b))),
                ),
              )),
          // Remaining empty ball slots
          ...List.generate(6 - balls.where((b) =>
              !b.startsWith('Wd') && !b.startsWith('Nb')).length, (_) =>
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
            )),
        ],
      ),
    );
  }
}

// ─── Run button ───────────────────────────────────────────────────────────────
class _RunBtn extends StatelessWidget {
  final String label;
  final String? sublabel;
  final Color color;
  final bool big;
  final VoidCallback? onTap;
  const _RunBtn({required this.label, this.sublabel, required this.color,
      this.big = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: onTap == null ? Colors.grey.shade200 : color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(80),
                blurRadius: 6, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: big ? 42 : 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              if (sublabel != null)
                Text(sublabel!,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white70,
                        letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Extra button ─────────────────────────────────────────────────────────────
class _ExtraBtn extends StatelessWidget {
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback? onTap;
  const _ExtraBtn({required this.label, this.sublabel,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              if (sublabel != null)
                Text(sublabel!,
                    style: TextStyle(fontSize: 10, color: color.withAlpha(180))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pick Player Sheet ────────────────────────────────────────────────────────
class _PickPlayerSheet extends StatelessWidget {
  final String title, subtitle;
  final List<TournamentPlayer> players;
  final Color color;
  final void Function(TournamentPlayer) onPick;
  const _PickPlayerSheet({required this.title, required this.subtitle,
      required this.players, required this.color, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(
                  color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
        const Divider(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 350),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: players.length,
            itemBuilder: (_, i) {
              final p = players[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withAlpha(30),
                  child: Text(p.name[0].toUpperCase(),
                      style: TextStyle(color: color,
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                title: Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: p.jerseyNumber != null
                    ? Text('#${p.jerseyNumber}') : null,
                onTap: () { Navigator.pop(context); onPick(p); },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Setup Sheet ──────────────────────────────────────────────────────────────
class _SetupSheet extends StatefulWidget {
  final Map<String, _BatsmanInfo> allBatters;
  final Map<String, _BowlerInfo>  allBowlers;
  final List<TournamentPlayer> battingPlayers, bowlingPlayers;
  final String? strikerId, nonStrikerId, bowlerId;
  final void Function(String?, String?, String?) onConfirm;
  final Future<void> Function(TournamentPlayer) addBatter;
  final Future<void> Function(TournamentPlayer) addBowler;

  const _SetupSheet({
    required this.allBatters, required this.allBowlers,
    required this.battingPlayers, required this.bowlingPlayers,
    required this.strikerId, required this.nonStrikerId, required this.bowlerId,
    required this.onConfirm, required this.addBatter, required this.addBowler,
  });

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  String? _striker, _nonStriker, _bowler;

  @override
  void initState() {
    super.initState();
    _striker    = widget.strikerId;
    _nonStriker = widget.nonStrikerId;
    _bowler     = widget.bowlerId;
  }

  List<DropdownMenuItem<String>> _batterItems() =>
      widget.allBatters.entries
          .where((e) => e.value.isBatting)
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value.name),
              ))
          .toList();

  List<DropdownMenuItem<String>> _bowlerItems() =>
      widget.allBowlers.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value.name),
              ))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Setup Batsmen & Bowler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Striker
                _DDRow(
                  label: '★  Striker',
                  value: _striker,
                  items: _batterItems(),
                  color: _kGreenLight,
                  onChanged: (v) => setState(() => _striker = v),
                  onAdd: () async {
                    Navigator.pop(context);
                    final p = await _pickPlayer(context, widget.battingPlayers);
                    if (p != null) await widget.addBatter(p);
                  },
                ),
                const SizedBox(height: 10),
                // Non-striker
                _DDRow(
                  label: '   Non-striker',
                  value: _nonStriker,
                  items: _batterItems(),
                  color: Colors.black87,
                  onChanged: (v) => setState(() => _nonStriker = v),
                  onAdd: null,
                ),
                const SizedBox(height: 10),
                // Bowler
                _DDRow(
                  label: '⚪  Bowler',
                  value: _bowler,
                  items: _bowlerItems(),
                  color: Colors.indigo,
                  onChanged: (v) => setState(() => _bowler = v),
                  onAdd: () async {
                    Navigator.pop(context);
                    final p = await _pickPlayer(context, widget.bowlingPlayers);
                    if (p != null) await widget.addBowler(p);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _kGreenLight),
                    onPressed: () {
                      widget.onConfirm(_striker, _nonStriker, _bowler);
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<TournamentPlayer?> _pickPlayer(
      BuildContext context, List<TournamentPlayer> players) async {
    return showModalBottomSheet<TournamentPlayer>(
      context: context,
      builder: (_) => _PickPlayerSheet(
        title: 'Select Player',
        subtitle: '',
        players: players,
        color: _kGreenLight,
        onPick: (p) => Navigator.pop(context, p),
      ),
    );
  }
}

class _DDRow extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final Color color;
  final void Function(String?) onChanged;
  final VoidCallback? onAdd;
  const _DDRow({required this.label, required this.value, required this.items,
      required this.color, required this.onChanged, required this.onAdd});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              hint: const Text('Select…'),
              items: items,
              onChanged: onChanged,
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: _kGreenLight),
              tooltip: 'Add new',
              onPressed: onAdd,
            ),
          ],
        ],
      );
}

// ─── Wicket Sheet ─────────────────────────────────────────────────────────────
class _WicketSheet extends StatefulWidget {
  final _BatsmanInfo striker;
  final _BowlerInfo bowler;
  final List<TournamentPlayer> bowlingPlayers;
  final void Function(String dismissal, String bowlerName, String fielderName) onConfirm;

  const _WicketSheet({required this.striker, required this.bowler,
      required this.bowlingPlayers, required this.onConfirm});

  @override
  State<_WicketSheet> createState() => _WicketSheetState();
}

class _WicketSheetState extends State<_WicketSheet> {
  String _dismissal = 'bowled';
  String _fielderName = '';

  static const _modes = [
    ('bowled',     'Bowled'),
    ('caught',     'Caught'),
    ('lbw',        'LBW'),
    ('runOut',     'Run Out'),
    ('stumped',    'Stumped'),
    ('hitWicket',  'Hit Wicket'),
  ];

  bool get _needsFielder =>
      ['caught', 'runOut', 'stumped'].contains(_dismissal);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _kRedBg, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Text('🏏 ', style: TextStyle(fontSize: 18)),
                  Text('WICKET — ${widget.striker.name}',
                      style: const TextStyle(
                          color: _kRed, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dismissal type
                const Text('How out?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                // 2-column grid for big tap targets
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  children: _modes.map((m) {
                    final sel = _dismissal == m.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _dismissal = m.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: sel ? _kRed : _kRedBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? _kRed : Colors.red.shade200,
                              width: sel ? 2 : 1),
                          boxShadow: sel
                              ? [BoxShadow(color: _kRed.withAlpha(80),
                                  blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(m.$2,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: sel ? Colors.white : _kRed)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Fielder (for caught/stumped/run out)
                if (_needsFielder) ...[
                  const SizedBox(height: 14),
                  Text(_dismissal == 'runOut' ? 'Fielder:' : 'Catcher / Fielder:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                        isDense: true, border: OutlineInputBorder(),
                        hintText: 'Select fielder'),
                    items: widget.bowlingPlayers
                        .map((p) => DropdownMenuItem(value: p.name, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _fielderName = v ?? ''),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onConfirm(
                        _dismissal,
                        widget.bowler.name,
                        _fielderName,
                      );
                    },
                    child: const Text('Confirm Wicket',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Bye/Leg Bye run picker ───────────────────────────────────────────────────
// ─── Innings complete banner ──────────────────────────────────────────────────
class _InningsCompleteBanner extends StatelessWidget {
  final String teamName;
  final int runs, wickets, overs, balls, inningsNumber;
  final VoidCallback onStartNext;
  final VoidCallback onClose;
  const _InningsCompleteBanner({
    required this.teamName, required this.runs, required this.wickets,
    required this.overs, required this.balls, required this.inningsNumber,
    required this.onStartNext, required this.onClose,
  });

  String get _ovDisp => balls == 0 ? '$overs.0' : '$overs.$balls';

  @override
  Widget build(BuildContext context) {
    final isFirst = inningsNumber == 1;
    return Container(
      width: double.infinity,
      color: isFirst ? _kGreen : _kRed,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Innings ${isFirst ? "1" : "2"} Complete!',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$teamName  $runs/${wickets < 10 ? wickets : "all out"}  ($_ovDisp ov)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (isFirst)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kGreen,
                      elevation: 0,
                    ),
                    onPressed: onStartNext,
                    child: const Text('Start 2nd Innings',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              if (!isFirst)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kRed,
                      elevation: 0,
                    ),
                    onPressed: onClose,
                    child: const Text('Match Complete — Close',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ByeRunDialog extends StatelessWidget {
  final String title;
  final void Function(int) onPick;
  const _ByeRunDialog({required this.title, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Wrap(
        spacing: 12, runSpacing: 12,
        children: [1, 2, 3, 4].map((n) => GestureDetector(
          onTap: () { Navigator.pop(context); onPick(n); },
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey, width: 1.5),
            ),
            child: Center(
              child: Text('$n', style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
            ),
          ),
        )).toList(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ],
    );
  }
}
