import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'cricket_scorecard_screen.dart';
import 'tournament_screen.dart';

// ─── Tournament Detail Screen ─────────────────────────────────────────────────
class TournamentDetailScreen extends ConsumerStatefulWidget {
  final Tournament tournament;
  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final canScore = widget.tournament.canScore(user?.uid ?? '', isAdmin);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(widget.tournament.name),
        actions: [
          if (isAdmin) ...[
            if (widget.tournament.sport == 'Cricket')
              IconButton(
                icon: const Icon(Icons.sports_cricket),
                tooltip: 'Cricket Settings',
                onPressed: () => _showCricketSettings(context),
              ),
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Manage Scorekeepers',
              onPressed: () => _showScorekeeperDialog(context),
            ),
            _StatusMenu(tournament: widget.tournament),
          ],
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Fixtures'),
            Tab(text: 'Players'),
            Tab(text: 'Teams'),
            Tab(text: 'Standings'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FixturesTab(
              tournament: widget.tournament,
              canScore: canScore,
              isAdmin: isAdmin,
              currentUid: user?.uid ?? ''),
          _PlayersTab(tournament: widget.tournament, isAdmin: isAdmin),
          _TeamsTab(tournament: widget.tournament, isAdmin: isAdmin),
          _StandingsTab(tournament: widget.tournament),
          _PerformanceTab(tournament: widget.tournament),
        ],
      ),
    );
  }

  void _showScorekeeperDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ScorekeeperDialog(tournament: widget.tournament),
    );
  }

  void _showCricketSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CricketSettingsSheet(
        maxOvers: widget.tournament.maxOvers,
        playersPerSide: widget.tournament.playersPerSide,
        maxOversPerBowler: widget.tournament.maxOversPerBowler,
        onSave: (overs, players, maxBowler) async {
          await FirebaseFirestore.instance
              .collection('tournaments')
              .doc(widget.tournament.id)
              .update({
            'maxOvers': overs,
            'playersPerSide': players,
            'maxOversPerBowler': maxBowler,
          });
        },
      ),
    );
  }
}

// ─── Status Menu ─────────────────────────────────────────────────────────────
class _StatusMenu extends ConsumerWidget {
  final Tournament tournament;
  const _StatusMenu({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<TournamentStatus>(
      icon: const Icon(Icons.more_vert),
      onSelected: (status) {
        ref.read(firestoreServiceProvider).updateTournament(
          tournament.id, {'status': status.name},
        );
      },
      itemBuilder: (_) => TournamentStatus.values
          .map((s) => PopupMenuItem(
                value: s,
                child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
              ))
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FIXTURES TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _FixturesTab extends ConsumerWidget {
  final Tournament tournament;
  final bool canScore;
  final bool isAdmin;
  final String currentUid;

  const _FixturesTab({
    required this.tournament,
    required this.canScore,
    required this.isAdmin,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(fixturesProvider(tournament.id));
    final teamsAsync = ref.watch(teamsProvider(tournament.id));

    return fixturesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (fixtures) {
        final teams = teamsAsync.valueOrNull ?? [];
        return Column(
          children: [
            if (isAdmin) _FixtureActions(tournament: tournament, teams: teams, fixtures: fixtures),
            Expanded(
              child: fixtures.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('📋', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('No fixtures yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Add teams first, then generate fixtures',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : _FixtureList(
                      fixtures: fixtures,
                      tournament: tournament,
                      canScore: canScore,
                      currentUid: currentUid,
                      isAdmin: isAdmin,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FixtureActions extends ConsumerWidget {
  final Tournament tournament;
  final List<TournamentTeam> teams;
  final List<Fixture> fixtures;
  const _FixtureActions(
      {required this.tournament, required this.teams, required this.fixtures});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Auto Fixtures'),
              onPressed: teams.length < 2
                  ? null
                  : () => _generateAuto(context, ref),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Fixture'),
              onPressed: teams.length < 2
                  ? null
                  : () => _showAddFixture(context, ref),
            ),
          ),
          if (fixtures.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Clear all fixtures',
              onPressed: () => _confirmClear(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateAuto(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Auto-Generate Fixtures'),
        content: Text(
          tournament.format == TournamentFormat.league
              ? 'This will generate a round-robin league schedule (each team plays all others once). Clear existing fixtures first?'
              : 'This will generate knockout bracket fixtures. Team count should be a power of 2 (4, 8, 16…). Clear existing fixtures first?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Generate')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(firestoreServiceProvider).clearFixtures(tournament.id);
    final fixtures = tournament.format == TournamentFormat.league
        ? _buildLeagueFixtures(teams)
        : _buildKnockoutFixtures(teams);
    await ref.read(firestoreServiceProvider).addFixtures(fixtures);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${fixtures.length} fixtures')),
      );
    }
  }

  List<Fixture> _buildLeagueFixtures(List<TournamentTeam> teams) {
    final fixtures = <Fixture>[];
    int round = 1;
    for (int i = 0; i < teams.length - 1; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        fixtures.add(Fixture(
          id: '',
          tournamentId: tournament.id,
          homeTeamId: teams[i].id,
          homeTeamName: teams[i].name,
          awayTeamId: teams[j].id,
          awayTeamName: teams[j].name,
          round: round,
        ));
        round++;
      }
    }
    return fixtures;
  }

  List<Fixture> _buildKnockoutFixtures(List<TournamentTeam> teams) {
    final shuffled = List<TournamentTeam>.from(teams)..shuffle(Random());
    final fixtures = <Fixture>[];
    for (int i = 0; i < shuffled.length - 1; i += 2) {
      fixtures.add(Fixture(
        id: '',
        tournamentId: tournament.id,
        homeTeamId: shuffled[i].id,
        homeTeamName: shuffled[i].name,
        awayTeamId: shuffled[i + 1].id,
        awayTeamName: shuffled[i + 1].name,
        round: 1,
      ));
    }
    return fixtures;
  }

  void _showAddFixture(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) =>
          _AddFixtureDialog(tournament: tournament, teams: teams),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Fixtures?'),
        content: const Text('All fixtures will be deleted permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(firestoreServiceProvider).clearFixtures(tournament.id);
    }
  }
}

class _FixtureList extends StatelessWidget {
  final List<Fixture> fixtures;
  final Tournament tournament;
  final bool canScore;
  final String currentUid;
  final bool isAdmin;
  const _FixtureList({
    required this.fixtures,
    required this.tournament,
    required this.canScore,
    required this.currentUid,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    // Group by round
    final rounds = <int, List<Fixture>>{};
    for (final f in fixtures) {
      rounds.putIfAbsent(f.round, () => []).add(f);
    }
    final sortedRounds = rounds.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedRounds.length,
      itemBuilder: (context, i) {
        final round = sortedRounds[i];
        final roundFixtures = rounds[round]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                tournament.format == TournamentFormat.knockout
                    ? _knockoutRoundName(round, fixtures)
                    : 'Match Day $round',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            ...roundFixtures.map((f) => _FixtureCard(
                  fixture: f,
                  tournament: tournament,
                  canScore: canScore,
                  currentUid: currentUid,
                  isAdmin: isAdmin,
                )),
          ],
        );
      },
    );
  }

  String _knockoutRoundName(int round, List<Fixture> allFixtures) {
    final maxRound = allFixtures.map((f) => f.round).reduce(max);
    if (round == maxRound) return 'Final';
    if (round == maxRound - 1) return 'Semi-Final';
    if (round == maxRound - 2) return 'Quarter-Final';
    return 'Round $round';
  }
}

class _FixtureCard extends ConsumerWidget {
  final Fixture fixture;
  final Tournament tournament;
  final bool canScore;
  final String currentUid;
  final bool isAdmin;
  const _FixtureCard({
    required this.fixture,
    required this.tournament,
    required this.canScore,
    required this.currentUid,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tournament.sport == 'Cricket') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cricketInnings')
            .where('fixtureId', isEqualTo: fixture.id)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          docs.sort((a, b) {
            final ai = (a.data() as Map)['inningsNumber'] as int? ?? 0;
            final bi = (b.data() as Map)['inningsNumber'] as int? ?? 0;
            return ai.compareTo(bi);
          });

          // Map innings by batting team
          Map<String, dynamic>? homeInn, awayInn;
          for (final doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            final tid = d['battingTeamId'] as String? ?? '';
            if (tid == fixture.homeTeamId) homeInn = d;
            else if (tid == fixture.awayTeamId) awayInn = d;
          }

          return _buildCard(context, ref,
            homeScore: homeInn != null ? _scoreText(homeInn) : null,
            homeOvers: homeInn != null ? _oversText(homeInn) : null,
            awayScore: awayInn != null ? _scoreText(awayInn) : null,
            awayOvers: awayInn != null ? _oversText(awayInn) : null,
            resultLine: _cricketResult(docs),
          );
        },
      );
    }
    return _buildCard(context, ref,
      homeScore: fixture.homeScore?.toString(),
      awayScore: fixture.awayScore?.toString(),
      resultLine: fixture.status == FixtureStatus.completed
          ? (fixture.winner == fixture.homeTeamId
              ? '${fixture.homeTeamName} won'
              : fixture.winner == fixture.awayTeamId
                  ? '${fixture.awayTeamName} won'
                  : 'Draw')
          : null,
    );
  }

  String _scoreText(Map<String, dynamic> d) {
    final runs = d['totalRuns'] ?? 0;
    final wkts = d['totalWickets'] ?? 0;
    return '$runs/$wkts';
  }

  String _oversText(Map<String, dynamic> d) {
    final overs = d['overs'] ?? 0;
    final balls = d['balls'] ?? 0;
    return balls == 0 ? '$overs.0' : '$overs.$balls';
  }

  String? _cricketResult(List<QueryDocumentSnapshot> docs) {
    if (docs.length < 2) return null;
    // Find 1st and 2nd innings
    final sorted = [...docs]..sort((a, b) {
      final ai = (a.data() as Map)['inningsNumber'] as int? ?? 0;
      final bi = (b.data() as Map)['inningsNumber'] as int? ?? 0;
      return ai.compareTo(bi);
    });
    final d1 = sorted[0].data() as Map<String, dynamic>;
    final d2 = sorted[1].data() as Map<String, dynamic>;
    if (!(d2['isCompleted'] as bool? ?? false)) return null;
    final target = (d1['totalRuns'] as int? ?? 0) + 1;
    final chased = d2['totalRuns'] as int? ?? 0;
    final wkts   = d2['totalWickets'] as int? ?? 0;
    final batTeam2 = d2['battingTeamName'] as String? ?? '';
    if (chased >= target) {
      final wicketsLeft = 10 - wkts;
      return '$batTeam2 won by $wicketsLeft wickets';
    } else {
      final margin = target - 1 - chased;
      final bowlTeam2 = d2['bowlingTeamName'] as String? ?? '';
      return '$bowlTeam2 won by $margin runs';
    }
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref, {
    String? homeScore,
    String? homeOvers,
    String? awayScore,
    String? awayOvers,
    String? resultLine,
  }) {
    final homeWon = fixture.winner == fixture.homeTeamId ||
        (resultLine != null && resultLine.startsWith(fixture.homeTeamName));
    final awayWon = fixture.winner == fixture.awayTeamId ||
        (resultLine != null && resultLine.startsWith(fixture.awayTeamName));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: tournament.sport == 'Cricket'
            ? () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CricketScorecardScreen(
                    fixture: fixture,
                    tournament: tournament,
                    canScore: canScore,
                    currentUid: currentUid,
                  ),
                ))
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Scores row ──────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Home team
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TeamCircle(
                            name: fixture.homeTeamName, won: homeWon),
                        const SizedBox(height: 5),
                        Text(
                          fixture.homeTeamName,
                          style: TextStyle(
                            fontWeight: homeWon ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                            color: homeWon ? AppColors.mint : AppColors.ink,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  // Home score
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          homeScore ?? (fixture.status == FixtureStatus.scheduled ? '' : '-'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: homeWon ? AppColors.mint : AppColors.ink,
                          ),
                        ),
                        if (homeOvers != null)
                          Text('($homeOvers)',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                      ],
                    ),
                  ),
                  // Centre separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      fixture.status == FixtureStatus.live ? '●' : 'vs',
                      style: TextStyle(
                        fontSize: 13,
                        color: fixture.status == FixtureStatus.live
                            ? AppColors.success
                            : AppColors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Away score
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          awayScore ?? (fixture.status == FixtureStatus.scheduled ? '' : '-'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: awayWon ? AppColors.mint : AppColors.ink,
                          ),
                        ),
                        if (awayOvers != null)
                          Text('($awayOvers)',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                      ],
                    ),
                  ),
                  // Away team
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _TeamCircle(name: fixture.awayTeamName, won: awayWon, alignRight: true),
                        const SizedBox(height: 5),
                        Text(
                          fixture.awayTeamName,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: awayWon ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                            color: awayWon ? AppColors.mint : AppColors.ink,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Result / status line ────────────────────────────────
              if (resultLine != null)
                Text(
                  resultLine,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate,
                      fontWeight: FontWeight.w500),
                )
              else if (fixture.status == FixtureStatus.live)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('● LIVE',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                )
              else if (fixture.status == FixtureStatus.scheduled && fixture.scheduledAt != null)
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(fixture.scheduledAt!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate),
                )
              else if (fixture.status == FixtureStatus.cancelled)
                const Text('Cancelled',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.error)),

              const SizedBox(height: 4),
              const Divider(height: 1),

              // ── Actions row ─────────────────────────────────────────
              Row(
                children: [
                  _StatusBadge(status: fixture.status),
                  const Spacer(),
                  if (canScore && fixture.status != FixtureStatus.cancelled)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.mint,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                      icon: const Icon(Icons.scoreboard_outlined, size: 15),
                      label: Text(
                        tournament.sport == 'Cricket'
                            ? 'Scorecard'
                            : fixture.homeScore == null ? 'Add Score' : 'Edit Score',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _openScoring(context, ref),
                    ),
                  if (isAdmin)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () async {
                        await ref.read(firestoreServiceProvider)
                            .deleteFixture(tournament.id, fixture.id);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openScoring(BuildContext context, WidgetRef ref) {
    if (tournament.sport == 'Cricket') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CricketScorecardScreen(
            fixture: fixture,
            tournament: tournament,
            canScore: canScore,
            currentUid: currentUid,
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _ScoreDialog(
        fixture: fixture,
        tournament: tournament,
        currentUid: currentUid,
      ),
    );
  }
}

class _TeamCircle extends StatelessWidget {
  final String name;
  final bool won;
  final bool alignRight;
  const _TeamCircle({required this.name, this.won = false, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: won ? AppColors.mint.withAlpha(28) : AppColors.mist,
          shape: BoxShape.circle,
          border: Border.all(
            color: won ? AppColors.mint : AppColors.border,
            width: won ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: won ? AppColors.mint : AppColors.slate,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final FixtureStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case FixtureStatus.scheduled: return AppColors.warning;
      case FixtureStatus.live:      return AppColors.success;
      case FixtureStatus.completed: return AppColors.slate;
      case FixtureStatus.cancelled: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = status.name[0].toUpperCase() + status.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(60), width: 1),
      ),
      child: Text(label,
          style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Score Dialog ─────────────────────────────────────────────────────────────
class _ScoreDialog extends ConsumerStatefulWidget {
  final Fixture fixture;
  final Tournament tournament;
  final String currentUid;
  const _ScoreDialog({
    required this.fixture,
    required this.tournament,
    required this.currentUid,
  });

  @override
  ConsumerState<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends ConsumerState<_ScoreDialog> {
  late TextEditingController _homeCtrl;
  late TextEditingController _awayCtrl;
  FixtureStatus _status = FixtureStatus.completed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _homeCtrl = TextEditingController(
        text: widget.fixture.homeScore?.toString() ?? '');
    _awayCtrl = TextEditingController(
        text: widget.fixture.awayScore?.toString() ?? '');
    _status = widget.fixture.status == FixtureStatus.scheduled
        ? FixtureStatus.completed
        : widget.fixture.status;
  }

  @override
  void dispose() {
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final home = int.tryParse(_homeCtrl.text.trim());
    final away = int.tryParse(_awayCtrl.text.trim());
    if (home == null || away == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid scores')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(firestoreServiceProvider).updateFixtureScore(
        tournamentId: widget.tournament.id,
        fixtureId: widget.fixture.id,
        homeScore: home,
        awayScore: away,
        scoredByUid: widget.currentUid,
        status: _status,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Score'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(widget.fixture.homeTeamName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _homeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('vs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(widget.fixture.awayTeamName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _awayCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<FixtureStatus>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Match Status'),
            items: [
              FixtureStatus.live,
              FixtureStatus.completed,
              FixtureStatus.cancelled,
            ]
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Add Manual Fixture Dialog ────────────────────────────────────────────────
class _AddFixtureDialog extends ConsumerStatefulWidget {
  final Tournament tournament;
  final List<TournamentTeam> teams;
  const _AddFixtureDialog({required this.tournament, required this.teams});

  @override
  ConsumerState<_AddFixtureDialog> createState() => _AddFixtureDialogState();
}

class _AddFixtureDialogState extends ConsumerState<_AddFixtureDialog> {
  TournamentTeam? _home;
  TournamentTeam? _away;
  int _round = 1;
  DateTime? _scheduledAt;
  bool _saving = false;

  Future<void> _save() async {
    if (_home == null || _away == null || _home!.id == _away!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select two different teams')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(firestoreServiceProvider).addFixture(Fixture(
        id: '',
        tournamentId: widget.tournament.id,
        homeTeamId: _home!.id,
        homeTeamName: _home!.name,
        awayTeamId: _away!.id,
        awayTeamName: _away!.name,
        round: _round,
        scheduledAt: _scheduledAt,
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Fixture'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TournamentTeam>(
              decoration: const InputDecoration(labelText: 'Home Team'),
              items: widget.teams
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _home = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TournamentTeam>(
              decoration: const InputDecoration(labelText: 'Away Team'),
              items: widget.teams
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _away = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Round: '),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _round > 1 ? () => setState(() => _round--) : null),
                Text('$_round', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _round++)),
              ],
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_scheduledAt == null
                  ? 'Schedule Date & Time (optional)'
                  : DateFormat('dd MMM yyyy, HH:mm').format(_scheduledAt!)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d == null || !context.mounted) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (t != null) {
                  setState(() => _scheduledAt =
                      DateTime(d.year, d.month, d.day, t.hour, t.minute));
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEAMS TAB
// ═══════════════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════════
// PLAYERS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _PlayersTab extends ConsumerWidget {
  final Tournament tournament;
  final bool isAdmin;
  const _PlayersTab({required this.tournament, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(tournamentPlayersProvider(tournament.id));
    final teamsAsync = ref.watch(teamsProvider(tournament.id));

    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (players) {
        final teams = teamsAsync.valueOrNull ?? [];
        return Column(
          children: [
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Player'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => _AddPlayerDialog(tournament: tournament),
                    ),
                  ),
                ),
              ),
            // summary chips
            if (players.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    _InfoChip('${players.length} total', Colors.blueGrey),
                    const SizedBox(width: 8),
                    _InfoChip(
                      '${players.where((p) => p.isAssigned).length} assigned',
                      AppColors.green,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      '${players.where((p) => !p.isAssigned).length} unassigned',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: players.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👤', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('No players yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Add players to this tournament first',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _PlayerCard(
                        player: players[i],
                        tournament: tournament,
                        teams: teams,
                        isAdmin: isAdmin,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _PlayerCard extends ConsumerWidget {
  final TournamentPlayer player;
  final Tournament tournament;
  final List<TournamentTeam> teams;
  final bool isAdmin;
  const _PlayerCard({
    required this.player,
    required this.tournament,
    required this.teams,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _PlayerAvatar(player: player, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(player.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (player.jerseyNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('#${player.jerseyNumber}',
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player.isAssigned ? '🏅 ${player.teamName}' : 'Unassigned',
                    style: TextStyle(
                      fontSize: 12,
                      color: player.isAssigned ? AppColors.green : Colors.orange,
                    ),
                  ),
                  if (player.phone.isNotEmpty)
                    Text(player.phone,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (isAdmin)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  if (action == 'assign') {
                    _showAssignDialog(context, ref);
                  } else if (action == 'edit') {
                    showDialog(
                      context: context,
                      builder: (_) => _AddPlayerDialog(
                          tournament: tournament, existing: player),
                    );
                  } else if (action == 'delete') {
                    ref.read(firestoreServiceProvider).deleteTournamentPlayer(
                        tournament.id, player.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'assign',
                    child: Row(children: [
                      const Icon(Icons.group, size: 18),
                      const SizedBox(width: 8),
                      Text(player.isAssigned ? 'Change Team' : 'Assign to Team'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AssignTeamDialog(
        player: player,
        tournament: tournament,
        teams: teams,
      ),
    );
  }
}

class _AssignTeamDialog extends ConsumerWidget {
  final TournamentPlayer player;
  final Tournament tournament;
  final List<TournamentTeam> teams;
  const _AssignTeamDialog({
    required this.player,
    required this.tournament,
    required this.teams,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Assign ${player.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.isAssigned)
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.orange),
              title: const Text('Remove from team'),
              onTap: () async {
                await ref.read(firestoreServiceProvider).assignPlayerToTeam(
                  tournamentId: tournament.id,
                  playerId: player.id,
                  teamId: null,
                  teamName: null,
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ...teams.map((t) => ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.green.withOpacity(0.15),
                  child: Text(t.name[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.green, fontSize: 12)),
                ),
                title: Text(t.name),
                trailing: player.teamId == t.id
                    ? const Icon(Icons.check_circle, color: AppColors.green)
                    : null,
                onTap: () async {
                  await ref.read(firestoreServiceProvider).assignPlayerToTeam(
                    tournamentId: tournament.id,
                    playerId: player.id,
                    teamId: t.id,
                    teamName: t.name,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              )),
          if (teams.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Add teams first to assign players.',
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}

// ─── Player avatar (photo or initial fallback) ────────────────────────────────
class _PlayerAvatar extends StatelessWidget {
  final TournamentPlayer player;
  final double radius;
  const _PlayerAvatar({required this.player, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final bgColor = player.isAssigned
        ? AppColors.green.withAlpha(38)
        : Colors.orange.withAlpha(38);
    final fgColor = player.isAssigned ? AppColors.green : Colors.orange;

    if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(player.photoUrl!),
        backgroundColor: bgColor,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        player.name[0].toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.bold, color: fgColor),
      ),
    );
  }
}

class _AddPlayerDialog extends ConsumerStatefulWidget {
  final Tournament tournament;
  final TournamentPlayer? existing;
  const _AddPlayerDialog({required this.tournament, this.existing});

  @override
  ConsumerState<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends ConsumerState<_AddPlayerDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _jerseyCtrl = TextEditingController();
  bool _saving = false;
  XFile? _pickedImage;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _phoneCtrl.text = widget.existing!.phone;
      _jerseyCtrl.text = widget.existing!.jerseyNumber ?? '';
      _existingPhotoUrl = widget.existing!.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _jerseyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, maxHeight: 512, imageQuality: 85,
    );
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<String?> _uploadPhoto(String playerId) async {
    if (_pickedImage == null) return _existingPhotoUrl;
    final ref = FirebaseStorage.instance
        .ref('tournament_players/${widget.tournament.id}/$playerId.jpg');
    await ref.putFile(File(_pickedImage!.path));
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final jersey = _jerseyCtrl.text.trim().isEmpty ? null : _jerseyCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      if (widget.existing != null) {
        final photoUrl = await _uploadPhoto(widget.existing!.id);
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournament.id)
            .collection('players')
            .doc(widget.existing!.id)
            .update({
          'name': name,
          'phone': phone,
          'jerseyNumber': jersey,
          'photoUrl': photoUrl,
        });
      } else {
        // Create player doc first to get the ID, then upload photo
        final docRef = FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournament.id)
            .collection('players')
            .doc();
        final photoUrl = await _uploadPhoto(docRef.id);
        await docRef.set({
          'tournamentId': widget.tournament.id,
          'name': name,
          'phone': phone,
          'jerseyNumber': jersey,
          'photoUrl': photoUrl,
          'teamId': null,
          'teamName': null,
          'createdAt': Timestamp.now(),
        });
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _pickedImage != null || _existingPhotoUrl != null;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Player' : 'Edit Player'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo picker
            GestureDetector(
              onTap: _saving ? null : _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.green.withAlpha(30),
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : (_existingPhotoUrl != null
                            ? CachedNetworkImageProvider(_existingPhotoUrl!)
                            : null) as ImageProvider?,
                    child: !hasPhoto
                        ? Text(
                            _nameCtrl.text.isNotEmpty
                                ? _nameCtrl.text[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold,
                                color: AppColors.green),
                          )
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Player Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jerseyCtrl,
              decoration: const InputDecoration(
                labelText: 'Jersey Number (optional)',
                prefixIcon: Icon(Icons.tag),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
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

// ═══════════════════════════════════════════════════════════════════════════════
// TEAMS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _TeamsTab extends ConsumerWidget {
  final Tournament tournament;
  final bool isAdmin;
  const _TeamsTab({required this.tournament, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider(tournament.id));
    return teamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (teams) => Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('Add Team'),
                  onPressed: () => _showAddTeam(context, ref),
                ),
              ),
            ),
          Expanded(
            child: teams.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👥', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('No teams yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _TeamCard(
                      key: ValueKey(teams[i].id),
                      team: teams[i],
                      tournament: tournament,
                      isAdmin: isAdmin,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTeam(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AddTeamDialog(tournament: tournament),
    );
  }
}

class _TeamCard extends ConsumerWidget {
  final TournamentTeam team;
  final Tournament tournament;
  final bool isAdmin;
  const _TeamCard({
    super.key,
    required this.team,
    required this.tournament,
    required this.isAdmin,
  });

  Color get _color {
    try {
      return Color(int.parse(team.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _color.withOpacity(0.2),
          child: Text(team.name[0].toUpperCase(),
              style: TextStyle(color: _color, fontWeight: FontWeight.bold)),
        ),
        title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${team.playerIds.length} players'),
        trailing: isAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => _AddTeamDialog(
                        tournament: tournament,
                        existingTeam: team,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .deleteTeam(tournament.id, team.id),
                  ),
                ],
              )
            : null,
        children: [
          _TeamPlayerList(tournament: tournament, team: team),
        ],
      ),
    );
  }
}

// Shows players from the tournament pool that belong to this team
class _TeamPlayerList extends ConsumerWidget {
  final Tournament tournament;
  final TournamentTeam team;
  const _TeamPlayerList({required this.tournament, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read the team from the live stream so we always have the latest playerIds
    final liveTeam = ref
        .watch(teamsProvider(tournament.id))
        .valueOrNull
        ?.firstWhere((t) => t.id == team.id, orElse: () => team) ?? team;

    final playersAsync = ref.watch(tournamentPlayersProvider(tournament.id));

    if (playersAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (playersAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Error loading players: ${playersAsync.error}',
            style: const TextStyle(color: Colors.red, fontSize: 12)),
      );
    }

    final allPlayers = playersAsync.valueOrNull ?? [];
    final teamPlayers =
        allPlayers.where((p) => liveTeam.playerIds.contains(p.id)).toList();

    if (teamPlayers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No players assigned. Tap edit to select players.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }
    return Column(
      children: teamPlayers
          .map((p) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.green.withOpacity(0.1),
                  child: Text(p.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.green,
                          fontWeight: FontWeight.bold)),
                ),
                title: Text(p.name),
                trailing: p.jerseyNumber != null
                    ? Text('#${p.jerseyNumber}',
                        style: const TextStyle(
                            color: Colors.blueGrey, fontWeight: FontWeight.bold))
                    : null,
              ))
          .toList(),
    );
  }
}

class _AddTeamDialog extends ConsumerStatefulWidget {
  final Tournament tournament;
  final TournamentTeam? existingTeam;
  const _AddTeamDialog({required this.tournament, this.existingTeam});

  @override
  ConsumerState<_AddTeamDialog> createState() => _AddTeamDialogState();
}

class _AddTeamDialogState extends ConsumerState<_AddTeamDialog> {
  final _nameCtrl = TextEditingController();
  // selected player ids from tournament pool
  final Set<String> _selectedPlayerIds = {};
  String _colorHex = '#1A5C3A';
  bool _saving = false;

  static const _colors = [
    '#1A5C3A', '#2196F3', '#E91E63', '#FF9800', '#9C27B0',
    '#F44336', '#009688', '#3F51B5', '#795548', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTeam != null) {
      _nameCtrl.text = widget.existingTeam!.name;
      _colorHex = widget.existingTeam!.colorHex;
      _selectedPlayerIds.addAll(widget.existingTeam!.playerIds);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      final tournamentId = widget.tournament.id;

      String teamId;
      if (widget.existingTeam != null) {
        teamId = widget.existingTeam!.id;
        await fs.updateTeam(TournamentTeam(
          id: teamId,
          tournamentId: tournamentId,
          name: name,
          colorHex: _colorHex,
          playerIds: _selectedPlayerIds.toList(),
          createdAt: widget.existingTeam!.createdAt,
        ));
      } else {
        teamId = await fs.addTeam(TournamentTeam(
          id: '',
          tournamentId: tournamentId,
          name: name,
          colorHex: _colorHex,
          playerIds: _selectedPlayerIds.toList(),
          createdAt: DateTime.now(),
        ));
      }

      // Sync teamId on every selected/deselected player
      final prevIds = widget.existingTeam?.playerIds.toSet() ?? {};
      final futures = <Future>[];
      // Assign all newly selected players
      for (final pid in _selectedPlayerIds) {
        futures.add(fs.assignPlayerToTeam(
          tournamentId: tournamentId,
          playerId: pid,
          teamId: teamId,
          teamName: name,
        ));
      }
      // Clear players that were removed from this team
      for (final pid in prevIds) {
        if (!_selectedPlayerIds.contains(pid)) {
          futures.add(fs.assignPlayerToTeam(
            tournamentId: tournamentId,
            playerId: pid,
            teamId: null,
            teamName: null,
          ));
        }
      }
      await Future.wait(futures);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save team: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers =
        ref.watch(tournamentPlayersProvider(widget.tournament.id)).valueOrNull ?? [];

    // Only show players who are unassigned OR already belong to this team
    final availablePlayers = allPlayers.where((p) =>
        !p.isAssigned || p.teamId == widget.existingTeam?.id).toList();

    return AlertDialog(
      title: Text(widget.existingTeam == null ? 'Add Team' : 'Edit Team'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Team Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            const Text('Team Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((hex) {
                final c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _colorHex == hex
                          ? Border.all(width: 3, color: Colors.black)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Players', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_selectedPlayerIds.length} selected',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            if (allPlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No players in this tournament yet.\nAdd players from the Players tab first.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else if (availablePlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'All players are already assigned to other teams.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else
              ...availablePlayers.map((p) {
                final selected = _selectedPlayerIds.contains(p.id);
                return CheckboxListTile(
                  dense: true,
                  value: selected,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedPlayerIds.add(p.id);
                    } else {
                      _selectedPlayerIds.remove(p.id);
                    }
                  }),
                  title: Text(p.name),
                  subtitle: null,
                  secondary: p.jerseyNumber != null
                      ? Text('#${p.jerseyNumber}',
                          style: const TextStyle(
                              color: Colors.blueGrey, fontWeight: FontWeight.bold))
                      : null,
                  activeColor: AppColors.green,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
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

// ═══════════════════════════════════════════════════════════════════════════════
// STANDINGS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _StandingsTab extends ConsumerWidget {
  final Tournament tournament;
  const _StandingsTab({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tournament.format == TournamentFormat.knockout) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Knockout Tournament',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'Standings are not applicable for knockout format. Check the Fixtures tab to follow match progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final fixturesAsync = ref.watch(fixturesProvider(tournament.id));
    final teamsAsync = ref.watch(teamsProvider(tournament.id));

    return fixturesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (fixtures) {
        final teams = teamsAsync.valueOrNull ?? [];
        final standings = _computeStandings(teams, fixtures);

        if (standings.isEmpty) {
          return const Center(
            child: Text('No data yet. Scores will appear here once matches are played.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const _StandingsHeader(),
                const Divider(height: 1),
                ...standings.asMap().entries.map((e) =>
                    _StandingsRow(standing: e.value, position: e.key + 1)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TeamStanding> _computeStandings(
      List<TournamentTeam> teams, List<Fixture> fixtures) {
    final map = <String, TeamStanding>{};
    for (final t in teams) {
      map[t.id] = TeamStanding(teamId: t.id, teamName: t.name);
    }
    for (final f in fixtures) {
      if (f.status != FixtureStatus.completed) continue;
      if (f.homeScore == null || f.awayScore == null) continue;
      final home = map[f.homeTeamId];
      final away = map[f.awayTeamId];
      if (home == null || away == null) continue;
      home.played++;
      away.played++;
      home.goalsFor += f.homeScore!;
      home.goalsAgainst += f.awayScore!;
      away.goalsFor += f.awayScore!;
      away.goalsAgainst += f.homeScore!;
      if (f.homeScore! > f.awayScore!) {
        home.won++;
        away.lost++;
      } else if (f.awayScore! > f.homeScore!) {
        away.won++;
        home.lost++;
      } else {
        home.drawn++;
        away.drawn++;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) {
        final pts = b.points.compareTo(a.points);
        if (pts != 0) return pts;
        return b.goalDiff.compareTo(a.goalDiff);
      });
    return list;
  }
}

class _StandingsHeader extends StatelessWidget {
  const _StandingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 28, child: Text('P', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 28, child: Text('W', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 28, child: Text('D', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 28, child: Text('L', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 36, child: Text('GD', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 36, child: Text('Pts', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green))),
        ],
      ),
    );
  }
}

class _StandingsRow extends StatelessWidget {
  final TeamStanding standing;
  final int position;
  const _StandingsRow({required this.standing, required this.position});

  @override
  Widget build(BuildContext context) {
    final isTop = position <= 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isTop ? AppColors.green.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$position',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTop ? AppColors.green : Colors.grey)),
          ),
          Expanded(child: Text(standing.teamName, style: const TextStyle(fontWeight: FontWeight.w500))),
          SizedBox(width: 28, child: Text('${standing.played}', textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('${standing.won}', textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('${standing.drawn}', textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('${standing.lost}', textAlign: TextAlign.center)),
          SizedBox(
            width: 36,
            child: Text(
              standing.goalDiff >= 0 ? '+${standing.goalDiff}' : '${standing.goalDiff}',
              textAlign: TextAlign.center,
              style: TextStyle(color: standing.goalDiff >= 0 ? Colors.green : Colors.red),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('${standing.points}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCOREKEEPER MANAGEMENT DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _ScorekeeperDialog extends ConsumerStatefulWidget {
  final Tournament tournament;
  const _ScorekeeperDialog({required this.tournament});

  @override
  ConsumerState<_ScorekeeperDialog> createState() => _ScorekeeperDialogState();
}

class _ScorekeeperDialogState extends ConsumerState<_ScorekeeperDialog> {
  final _phoneCtrl = TextEditingController();
  bool _searching = false;
  String? _errorMsg;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _grantByPhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _searching = true; _errorMsg = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        setState(() => _errorMsg = 'No user found with this phone number');
        return;
      }
      final uid = snap.docs.first.id;
      await ref.read(firestoreServiceProvider).addScorekeeperByUid(
        widget.tournament.id, uid,
      );
      _phoneCtrl.clear();
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scorekeepers = widget.tournament.scorekeeperUids;

    return AlertDialog(
      title: const Text('Manage Scorekeepers'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grant users permission to enter scores for this tournament.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Grant by Phone:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+91XXXXXXXXXX',
                        errorText: _errorMsg,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _searching ? null : _grantByPhone,
                    child: _searching
                        ? const SizedBox.square(dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Grant'),
                  ),
                ],
              ),
              if (scorekeepers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Current Scorekeepers:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ref.watch(allUsersProvider).when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (users) {
                    final skUsers = users.where((u) => scorekeepers.contains(u.uid)).toList();
                    return Column(
                      children: skUsers.map((u) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person),
                        title: Text(u.name),
                        subtitle: Text(u.phone),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => ref.read(firestoreServiceProvider)
                              .removeScorekeeperByUid(widget.tournament.id, u.uid),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

// ─── Performance Tab ──────────────────────────────────────────────────────────
class _PerformanceTab extends StatelessWidget {
  final Tournament tournament;
  const _PerformanceTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.sport != 'Cricket') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📊', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Stats coming soon',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('battingScores')
          .where('tournamentId', isEqualTo: tournament.id)
          .snapshots(),
      builder: (context, batSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bowlingFigures')
              .where('tournamentId', isEqualTo: tournament.id)
              .snapshots(),
          builder: (context, bowlSnap) {
            final batDocs = batSnap.data?.docs ?? [];
            final bowlDocs = bowlSnap.data?.docs ?? [];

            // Aggregate batting by playerId
            final batMap = <String, _BatStat>{};
            for (final doc in batDocs) {
              final d = doc.data() as Map<String, dynamic>;
              final pid = d['playerId'] as String? ?? doc.id;
              final name = d['playerName'] as String? ?? '?';
              final runs = d['runs'] as int? ?? 0;
              final balls = d['balls'] as int? ?? 0;
              final fours = d['fours'] as int? ?? 0;
              final sixes = d['sixes'] as int? ?? 0;
              final dismissed = (d['dismissal'] as String? ?? '') != 'batting';
              final stat = batMap.putIfAbsent(pid, () => _BatStat(name: name));
              stat.runs += runs;
              stat.balls += balls;
              stat.fours += fours;
              stat.sixes += sixes;
              stat.innings += 1;
              if (dismissed) stat.outs += 1;
            }

            // Aggregate bowling by playerId
            final bowlMap = <String, _BowlStat>{};
            for (final doc in bowlDocs) {
              final d = doc.data() as Map<String, dynamic>;
              final pid = d['playerId'] as String? ?? doc.id;
              final name = d['playerName'] as String? ?? '?';
              final wkts = d['wickets'] as int? ?? 0;
              final runs = d['runs'] as int? ?? 0;
              final overs = d['overs'] as int? ?? 0;
              final balls = d['balls'] as int? ?? 0;
              final stat = bowlMap.putIfAbsent(pid, () => _BowlStat(name: name));
              stat.wickets += wkts;
              stat.runs += runs;
              stat.totalBalls += overs * 6 + balls;
            }

            final topBat = batMap.values.toList()
              ..sort((a, b) => b.runs != a.runs
                  ? b.runs.compareTo(a.runs)
                  : b.strikeRate.compareTo(a.strikeRate));

            final topBowl = bowlMap.values.toList()
              ..sort((a, b) => b.wickets != a.wickets
                  ? b.wickets.compareTo(a.wickets)
                  : a.economy.compareTo(b.economy));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatSection(
                  title: 'Top Batters',
                  icon: Icons.sports_cricket,
                  color: AppColors.green,
                  empty: topBat.isEmpty,
                  headerLabels: const ['Player', 'Inn', 'Runs', 'SR'],
                  children: topBat.take(10).toList().asMap().entries.map((e) =>
                      _BatRow(rank: e.key + 1, stat: e.value)).toList(),
                ),
                const SizedBox(height: 20),
                _StatSection(
                  title: 'Top Bowlers',
                  icon: Icons.lens_blur,
                  color: Colors.indigo,
                  empty: topBowl.isEmpty,
                  headerLabels: const ['Player', 'Wkts', 'Overs', 'Econ'],
                  children: topBowl.take(10).toList().asMap().entries.map((e) =>
                      _BowlRow(rank: e.key + 1, stat: e.value)).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BatStat {
  final String name;
  int runs = 0, balls = 0, fours = 0, sixes = 0, innings = 0, outs = 0;
  _BatStat({required this.name});
  double get strikeRate => balls == 0 ? 0 : runs / balls * 100;
  double get average => outs == 0 ? runs.toDouble() : runs / outs;
}

class _BowlStat {
  final String name;
  int wickets = 0, runs = 0, totalBalls = 0;
  _BowlStat({required this.name});
  String get oversStr {
    final o = totalBalls ~/ 6;
    final b = totalBalls % 6;
    return b == 0 ? '$o.0' : '$o.$b';
  }
  double get economy => totalBalls == 0 ? 0 : runs / (totalBalls / 6);
}

class _StatSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool empty;
  final List<Widget> children;
  final List<String> headerLabels;
  const _StatSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.empty,
    required this.children,
    required this.headerLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header with gradient strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              border: Border(bottom: BorderSide(color: color.withAlpha(40))),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color)),
              ],
            ),
          ),
          if (empty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(icon, size: 32, color: AppColors.border),
                  const SizedBox(height: 8),
                  const Text('No data yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate, fontSize: 13)),
                ],
              ),
            )
          else ...[
            // Column headers
            Container(
              color: AppColors.mist,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(headerLabels[0],
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(headerLabels[1],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(headerLabels[2],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(headerLabels[3],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _BatRow extends StatelessWidget {
  final int rank;
  final _BatStat stat;
  const _BatRow({required this.rank, required this.stat});

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    return Container(
      decoration: BoxDecoration(
        color: isTop ? AppColors.mint.withAlpha(14) : null,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$rank',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                    color: isTop ? AppColors.mint : AppColors.slate)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.name,
                    style: TextStyle(
                        fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.ink)),
                if (stat.sixes > 0 || stat.fours > 0)
                  Text('${stat.fours}×4  ${stat.sixes}×6',
                      style: const TextStyle(fontSize: 10, color: AppColors.slate)),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('${stat.innings}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate)),
          ),
          SizedBox(
            width: 52,
            child: Text('${stat.runs}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isTop ? AppColors.mint : AppColors.ink)),
          ),
          SizedBox(
            width: 48,
            child: Text(stat.strikeRate.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate)),
          ),
        ],
      ),
    );
  }
}

class _BowlRow extends StatelessWidget {
  final int rank;
  final _BowlStat stat;
  const _BowlRow({required this.rank, required this.stat});

  static const _bowlAccent = AppColors.info;

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    return Container(
      decoration: BoxDecoration(
        color: isTop ? _bowlAccent.withAlpha(14) : null,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$rank',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                    color: isTop ? _bowlAccent : AppColors.slate)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(stat.name,
                style: TextStyle(
                    fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.ink)),
          ),
          SizedBox(
            width: 36,
            child: Text('${stat.wickets}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isTop ? _bowlAccent : AppColors.ink)),
          ),
          SizedBox(
            width: 52,
            child: Text(stat.oversStr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate)),
          ),
          SizedBox(
            width: 48,
            child: Text(stat.economy.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate)),
          ),
        ],
      ),
    );
  }
}

