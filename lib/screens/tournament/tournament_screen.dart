import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'tournament_detail_screen.dart';

// ─── Sports list ──────────────────────────────────────────────────────────────
const _sports = [
  ('⚽', 'Football'),
  ('🏏', 'Cricket'),
  ('🏸', 'Badminton'),
  ('🏐', 'Volleyball'),
  ('🏀', 'Basketball'),
  ('🎾', 'Tennis'),
  ('🏓', 'Table Tennis'),
  ('🤸', 'Kabaddi'),
  ('🏑', 'Hockey'),
  ('🎱', 'Carrom'),
  ('🏆', 'Other'),
];

// ─── Tournament List Screen ───────────────────────────────────────────────────
class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final tournamentsAsync = ref.watch(tournamentsProvider);
    final canCreate = user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Tournaments 🏆'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref, user!),
              icon: const Icon(Icons.add),
              label: const Text('New Tournament'),
            )
          : null,
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏆', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('No tournaments yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Admins can create tournaments using the + button',
                      style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _TournamentCard(tournament: tournaments[i]),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateTournamentDialog(user: user),
    );
  }
}

// ─── Tournament Card ──────────────────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  const _TournamentCard({required this.tournament});

  Color get _statusColor {
    switch (tournament.status) {
      case TournamentStatus.upcoming: return Colors.orange;
      case TournamentStatus.ongoing: return Colors.green;
      case TournamentStatus.completed: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sport = _sports.firstWhere(
      (s) => s.$2 == tournament.sport,
      orElse: () => ('🏆', tournament.sport),
    );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TournamentDetailScreen(tournament: tournament),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(sport.$1, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(tournament.format == TournamentFormat.league ? 'League' : 'Knockout',
                            AppColors.green),
                        const SizedBox(width: 6),
                        _Chip(sport.$2, Colors.blueGrey),
                      ],
                    ),
                    if (tournament.startDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd MMM').format(tournament.startDate!)}'
                        '${tournament.endDate != null ? ' – ${DateFormat('dd MMM yyyy').format(tournament.endDate!)}' : ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tournament.status.name[0].toUpperCase() + tournament.status.name.substring(1),
                  style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ─── Create Tournament Dialog ─────────────────────────────────────────────────
class _CreateTournamentDialog extends ConsumerStatefulWidget {
  final AppUser user;
  const _CreateTournamentDialog({required this.user});

  @override
  ConsumerState<_CreateTournamentDialog> createState() => _CreateTournamentDialogState();
}

class _CreateTournamentDialogState extends ConsumerState<_CreateTournamentDialog> {
  final _nameCtrl = TextEditingController();
  String _sport = 'Football';
  TournamentFormat _format = TournamentFormat.league;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;
  // Cricket settings
  int? _maxOvers;
  int? _playersPerSide;
  int? _maxOversPerBowler;

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
      final t = Tournament(
        id: '',
        name: name,
        sport: _sport,
        format: _format,
        createdBy: widget.user.uid,
        createdByName: widget.user.name,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: DateTime.now(),
        maxOvers: _maxOvers,
        playersPerSide: _playersPerSide,
        maxOversPerBowler: _maxOversPerBowler,
      );
      await ref.read(firestoreServiceProvider).createTournament(t);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Tournament'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tournament Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            const Text('Sport', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sports.map((s) => ChoiceChip(
                label: Text('${s.$1} ${s.$2}'),
                selected: _sport == s.$2,
                onSelected: (_) => setState(() => _sport = s.$2),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Format', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<TournamentFormat>(
                    title: const Text('League'),
                    value: TournamentFormat.league,
                    groupValue: _format,
                    onChanged: (v) => setState(() => _format = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<TournamentFormat>(
                    title: const Text('Knockout'),
                    value: TournamentFormat.knockout,
                    groupValue: _format,
                    onChanged: (v) => setState(() => _format = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_startDate == null
                        ? 'Start Date'
                        : DateFormat('dd MMM').format(_startDate!)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _startDate = d);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_endDate == null
                        ? 'End Date'
                        : DateFormat('dd MMM').format(_endDate!)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _endDate = d);
                    },
                  ),
                ),
              ],
            ),
            if (_sport == 'Cricket') ...[
              const SizedBox(height: 16),
              CricketSettingsTile(
                maxOvers: _maxOvers,
                playersPerSide: _playersPerSide,
                maxOversPerBowler: _maxOversPerBowler,
                onChanged: (ov, pl, mb) => setState(() {
                  _maxOvers = ov;
                  _playersPerSide = pl;
                  _maxOversPerBowler = mb;
                }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox.square(dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ─── Cricket settings tile (shown in create/edit dialogs) ────────────────────
class CricketSettingsTile extends StatelessWidget {
  final int? maxOvers, playersPerSide, maxOversPerBowler;
  final void Function(int? overs, int? players, int? maxBowlerOvers) onChanged;
  const CricketSettingsTile({
    required this.maxOvers, required this.playersPerSide,
    required this.maxOversPerBowler, required this.onChanged,
  });

  String get _summary {
    if (maxOvers == null && playersPerSide == null && maxOversPerBowler == null) {
      return 'Tap to configure';
    }
    final parts = <String>[];
    if (maxOvers != null) parts.add('${maxOvers}ov');
    if (playersPerSide != null) parts.add('${playersPerSide}pl');
    if (maxOversPerBowler != null) parts.add('max ${maxOversPerBowler}ov/bowler');
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => CricketSettingsSheet(
          maxOvers: maxOvers,
          playersPerSide: playersPerSide,
          maxOversPerBowler: maxOversPerBowler,
          onSave: onChanged,
        ),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Text('🏏 ', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cricket Settings',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(_summary,
                      style: TextStyle(fontSize: 12,
                          color: maxOvers == null ? Colors.grey : Colors.green.shade700)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Cricket settings bottom sheet ───────────────────────────────────────────
class CricketSettingsSheet extends StatefulWidget {
  final int? maxOvers, playersPerSide, maxOversPerBowler;
  final void Function(int? overs, int? players, int? maxBowlerOvers) onSave;
  const CricketSettingsSheet({
    required this.maxOvers, required this.playersPerSide,
    required this.maxOversPerBowler, required this.onSave,
  });

  @override
  State<CricketSettingsSheet> createState() => CricketSettingsSheetState();
}

class CricketSettingsSheetState extends State<CricketSettingsSheet> {
  late TextEditingController _oversCtrl, _playersCtrl, _maxBowlerCtrl;
  String _preset = 'custom';

  static const _presets = [
    ('T20',   20,  11, 4),
    ('ODI',   50,  11, 10),
    ('T10',   10,  11, 2),
    ('Test',  90,  11, 999),
    ('Gully', 5,   6,  2),
  ];

  @override
  void initState() {
    super.initState();
    _oversCtrl     = TextEditingController(text: widget.maxOvers?.toString() ?? '');
    _playersCtrl   = TextEditingController(text: widget.playersPerSide?.toString() ?? '');
    _maxBowlerCtrl = TextEditingController(text: widget.maxOversPerBowler?.toString() ?? '');
  }

  @override
  void dispose() {
    _oversCtrl.dispose(); _playersCtrl.dispose(); _maxBowlerCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String name, int overs, int players, int maxBowler) {
    setState(() {
      _preset = name;
      _oversCtrl.text = '$overs';
      _playersCtrl.text = '$players';
      _maxBowlerCtrl.text = maxBowler == 999 ? '' : '$maxBowler';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(
              children: [
                const Text('🏏 Cricket Settings',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          // Presets
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Format Presets',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.grey, letterSpacing: 0.3)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _presets.map((p) {
                    final selected = _preset == p.$1;
                    return ChoiceChip(
                      label: Text(p.$1),
                      selected: selected,
                      selectedColor: Colors.green.shade700,
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight: FontWeight.w600),
                      onSelected: (_) => _applyPreset(p.$1, p.$2, p.$3, p.$4),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(),
          // Custom fields
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Custom Settings',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.grey, letterSpacing: 0.3)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: CricketSettingField(
                      ctrl: _oversCtrl,
                      label: 'Overs per innings',
                      hint: 'e.g. 20',
                      icon: Icons.timer_outlined,
                      onChange: () => setState(() => _preset = 'custom'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: CricketSettingField(
                      ctrl: _playersCtrl,
                      label: 'Players per side',
                      hint: 'e.g. 11',
                      icon: Icons.group_outlined,
                      onChange: () => setState(() => _preset = 'custom'),
                    )),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: CricketSettingField(
                      ctrl: _maxBowlerCtrl,
                      label: 'Max overs per bowler',
                      hint: 'e.g. 4',
                      icon: Icons.sports_cricket,
                      onChange: () => setState(() => _preset = 'custom'),
                    )),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        minimumSize: const Size.fromHeight(46)),
                    onPressed: () {
                      final overs    = int.tryParse(_oversCtrl.text.trim());
                      final players  = int.tryParse(_playersCtrl.text.trim());
                      final maxBowl  = int.tryParse(_maxBowlerCtrl.text.trim());
                      widget.onSave(overs, players, maxBowl);
                      Navigator.pop(context);
                    },
                    child: const Text('Save Settings',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CricketSettingField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final VoidCallback onChange;
  const CricketSettingField({required this.ctrl, required this.label, required this.hint,
      required this.icon, required this.onChange});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        onChanged: (_) => onChange(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
}
