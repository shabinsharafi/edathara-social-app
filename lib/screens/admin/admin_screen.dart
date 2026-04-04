import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

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
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Admin Panel ⚙️'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.mint,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.mint,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '🏟 Grounds'),
            Tab(text: '🚫 Slots'),
            Tab(text: '📣 News'),
            Tab(text: '💰 Funds'),
            Tab(text: '👤 Admins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _GroundsTab(),
          _BlockSlotsTab(),
          _NewsTab(),
          _FundsTab(),
          _AdminsTab(),
        ],
      ),
    );
  }
}

// ─── Grounds Tab ──────────────────────────────────────────────────────────────
class _GroundsTab extends ConsumerWidget {
  const _GroundsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grounds = ref.watch(allGroundsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Ground'),
        onPressed: () => _showAddGroundDialog(context, ref, grounds),
      ),
      body: grounds.isEmpty
          ? const EmptyState(emoji: '🏟', title: 'No grounds yet',
              subtitle: 'Tap + to add your first play area')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: grounds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _GroundAdminCard(ground: grounds[i], allGrounds: grounds)
                  .animate().fadeIn(delay: (i * 60).ms),
            ),
    );
  }

  void _showAddGroundDialog(BuildContext context, WidgetRef ref, List<PlayGround> all) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedIcon = '🏟';
    String selectedColor = '#1A5C3A';
    final defaultSlots = ['06:00','07:00','08:00','09:00','10:00','14:00','15:00','16:00','17:00','18:00','19:00'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('New Play Area', style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 20),
                // Icon picker
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600,
                    color: AppColors.slate, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: ['🏟','🏏','⚽','🏸','🎾','🏐','🏑','🥊','🏊','🎱'].map((e) =>
                    GestureDetector(
                      onTap: () => setS(() => selectedIcon = e),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: selectedIcon == e
                              ? AppColors.mint.withOpacity(0.15) : AppColors.mist,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedIcon == e ? AppColors.mint : AppColors.border,
                            width: selectedIcon == e ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),
                // Color picker
                const Text('Color', style: TextStyle(fontWeight: FontWeight.w600,
                    color: AppColors.slate, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: {
                    '#1A5C3A': AppColors.green,
                    '#1A3A6C': const Color(0xFF1A3A6C),
                    '#4A235A': const Color(0xFF4A235A),
                    '#C0392B': const Color(0xFFC0392B),
                    '#E8B84B': AppColors.gold,
                    '#2C3E50': const Color(0xFF2C3E50),
                  }.entries.map((e) =>
                    GestureDetector(
                      onTap: () => setS(() => selectedColor = e.key),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: e.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == e.key
                                ? AppColors.ink : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selectedColor == e.key
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Ground Name')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Create Ground',
                  fullWidth: true,
                  icon: Icons.add,
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    final g = PlayGround(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      icon: selectedIcon,
                      colorHex: selectedColor,
                      timeSlots: defaultSlots,
                      description: descCtrl.text.trim(),
                    );
                    await ref.read(firestoreServiceProvider).addGround(g);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroundAdminCard extends ConsumerWidget {
  final PlayGround ground;
  final List<PlayGround> allGrounds;
  const _GroundAdminCard({required this.ground, required this.allGrounds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = hexToColor(ground.colorHex);

    return AppCard(
      borderColor: color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ground.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ground.name,
                        style: const TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 16, color: AppColors.ink)),
                    Text('${ground.timeSlots.length} slots · '
                        '${ground.blockedSlots.length} blocked · '
                        '${ground.conflictIds.length} conflicts',
                        style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                  ],
                ),
              ),
              // Active toggle
              Switch(
                value: ground.isActive,
                activeColor: AppColors.mint,
                onChanged: (v) => ref.read(firestoreServiceProvider).updateGround(
                    ground.copyWith(isActive: v)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          const Divider(),
          // Conflict dependencies
          const Text('Conflict Dependencies',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                  color: AppColors.slate)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: allGrounds.where((g) => g.id != ground.id).map((other) {
              final hasConflict = ground.conflictIds.contains(other.id);
              return GestureDetector(
                onTap: () => _toggleConflict(ref, other),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasConflict
                        ? AppColors.error.withOpacity(0.1) : AppColors.mist,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasConflict ? AppColors.error : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(hasConflict ? Icons.link_off : Icons.link,
                          size: 14,
                          color: hasConflict ? AppColors.error : AppColors.slate),
                      const SizedBox(width: 4),
                      Text('${other.icon} ${other.name}',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: hasConflict ? AppColors.error : AppColors.slate,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleConflict(WidgetRef ref, PlayGround other) async {
    final fs = ref.read(firestoreServiceProvider);
    final has = ground.conflictIds.contains(other.id);
    final newIds = has
        ? ground.conflictIds.where((x) => x != other.id).toList()
        : [...ground.conflictIds, other.id];
    await fs.updateConflicts(ground.id, newIds);

    // Mirror on the other ground
    final otherHas = other.conflictIds.contains(ground.id);
    if (has && otherHas) {
      final otherNew = other.conflictIds.where((x) => x != ground.id).toList();
      await fs.updateConflicts(other.id, otherNew);
    } else if (!has && !otherHas) {
      await fs.updateConflicts(other.id, [...other.conflictIds, ground.id]);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Ground?'),
        content: Text('Are you sure you want to delete "${ground.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).deleteGround(ground.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Block Slots Tab ──────────────────────────────────────────────────────────
class _BlockSlotsTab extends ConsumerStatefulWidget {
  const _BlockSlotsTab();

  @override
  ConsumerState<_BlockSlotsTab> createState() => _BlockSlotsTabState();
}

class _BlockSlotsTabState extends ConsumerState<_BlockSlotsTab> {
  PlayGround? _selectedGround;

  @override
  Widget build(BuildContext context) {
    final grounds = ref.watch(allGroundsProvider).valueOrNull ?? [];
    if (_selectedGround == null && grounds.isNotEmpty) {
      _selectedGround = grounds.first;
    }
    // Keep in sync
    if (_selectedGround != null) {
      _selectedGround = grounds.firstWhere(
        (g) => g.id == _selectedGround!.id, orElse: () => grounds.first,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ground selector
          const Text('Select Ground', style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 10),
          if (grounds.isEmpty)
            const Text('No grounds configured')
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: grounds.map((g) {
                final isSelected = _selectedGround?.id == g.id;
                final color = hexToColor(g.colorHex);
                return GestureDetector(
                  onTap: () => setState(() => _selectedGround = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.1) : AppColors.mist,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(g.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(g.name, style: TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 13, color: isSelected ? color : AppColors.slate)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          if (_selectedGround != null) ...[
            const SizedBox(height: 24),
            const Text('Tap slot to toggle block', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 6),
            Row(children: [
              _LegendItem(color: AppColors.mint, label: 'Available'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.warning, label: 'Blocked'),
            ]),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8,
              children: _selectedGround!.timeSlots.map((slot) {
                final isBlocked = _selectedGround!.blockedSlots.contains(slot);
                return GestureDetector(
                  onTap: () async {
                    final fs = ref.read(firestoreServiceProvider);
                    if (isBlocked) {
                      await fs.unblockSlot(_selectedGround!.id, slot);
                    } else {
                      await fs.blockSlot(_selectedGround!.id, slot);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? AppColors.warning.withOpacity(0.1) : AppColors.mist,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBlocked ? AppColors.warning : AppColors.border,
                        width: isBlocked ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(slot, style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: isBlocked ? AppColors.warning : AppColors.ink,
                        )),
                        if (isBlocked)
                          const Text('BLOCKED', style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w800,
                              color: AppColors.warning)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Manage time slots
            const SizedBox(height: 24),
            const Text('Manage Time Slots', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 12),
            _AddSlotRow(ground: _selectedGround!),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
    ]);
  }
}

class _AddSlotRow extends ConsumerStatefulWidget {
  final PlayGround ground;
  const _AddSlotRow({required this.ground});

  @override
  ConsumerState<_AddSlotRow> createState() => _AddSlotRowState();
}

class _AddSlotRowState extends ConsumerState<_AddSlotRow> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            labelText: 'Add slot (e.g. 20:00)',
            prefixIcon: Icon(Icons.add_alarm_outlined),
          ),
        ),
      ),
      const SizedBox(width: 10),
      PrimaryButton(
        label: 'Add',
        onPressed: () async {
          if (_ctrl.text.isEmpty) return;
          final updated = [...widget.ground.timeSlots, _ctrl.text.trim()]..sort();
          await ref.read(firestoreServiceProvider).updateGround(
              widget.ground.copyWith(timeSlots: updated));
          _ctrl.clear();
        },
      ),
    ]);
  }
}

// ─── News Tab ─────────────────────────────────────────────────────────────────
class _NewsTab extends ConsumerStatefulWidget {
  const _NewsTab();

  @override
  ConsumerState<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends ConsumerState<_NewsTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Post News', style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                TextField(controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Headline')),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl, maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Content', alignLabelWithHint: true),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Publish News',
                  fullWidth: true,
                  isLoading: _isLoading,
                  icon: Icons.campaign_outlined,
                  onPressed: () async {
                    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
                    setState(() => _isLoading = true);
                    await ref.read(firestoreServiceProvider).addNews(
                      title: _titleCtrl.text.trim(),
                      body: _bodyCtrl.text.trim(),
                      authorId: user!.uid,
                      authorName: user.name,
                    );
                    _titleCtrl.clear(); _bodyCtrl.clear();
                    if (mounted) {
                      setState(() => _isLoading = false);
                      showSuccess(context, 'News published!');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Funds Tab ────────────────────────────────────────────────────────────────
class _FundsTab extends ConsumerStatefulWidget {
  const _FundsTab();

  @override
  ConsumerState<_FundsTab> createState() => _FundsTabState();
}

class _FundsTabState extends ConsumerState<_FundsTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _goalCtrl  = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final funds = ref.watch(fundraisersProvider).valueOrNull ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Campaign', style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(children: [
              TextField(controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Campaign Title')),
              const SizedBox(height: 12),
              TextField(controller: _descCtrl, maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description', alignLabelWithHint: true)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _goalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Goal (₹)', prefixIcon: Icon(Icons.currency_rupee)))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _deadlineCtrl,
                    decoration: const InputDecoration(labelText: 'Deadline (e.g. Dec 2025)'))),
              ]),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create Campaign',
                fullWidth: true,
                isLoading: _isLoading,
                icon: Icons.add,
                color: AppColors.gold,
                onPressed: () async {
                  if (_titleCtrl.text.isEmpty || _goalCtrl.text.isEmpty) return;
                  setState(() => _isLoading = true);
                  final f = Fundraiser(
                    id: const Uuid().v4(),
                    title: _titleCtrl.text.trim(),
                    description: _descCtrl.text.trim(),
                    goalAmount: double.tryParse(_goalCtrl.text) ?? 0,
                    deadline: _deadlineCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await ref.read(firestoreServiceProvider).addFundraiser(f);
                  _titleCtrl.clear(); _descCtrl.clear();
                  _goalCtrl.clear(); _deadlineCtrl.clear();
                  if (mounted) {
                    setState(() => _isLoading = false);
                    showSuccess(context, 'Campaign created!');
                  }
                },
              ),
            ]),
          ),
          if (funds.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Active Campaigns', style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 12),
            ...funds.map((f) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title, style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 14, color: AppColors.ink)),
                      Text('Goal: ₹${f.goalAmount.toStringAsFixed(0)} · ${f.deadline}',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                    ],
                  )),
                  Switch(
                    value: f.isActive,
                    activeColor: AppColors.mint,
                    onChanged: (v) => ref.read(firestoreServiceProvider)
                        .updateFundraiser(f.id, {'isActive': v}),
                  ),
                ]),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── Admins Tab ───────────────────────────────────────────────────────────────
class _AdminsTab extends ConsumerStatefulWidget {
  const _AdminsTab();

  @override
  ConsumerState<_AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends ConsumerState<_AdminsTab> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final admins = ref.watch(adminUsersProvider).valueOrNull ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grant Admin Access', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(children: [
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'User Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Grant Admin',
                fullWidth: true,
                isLoading: _isLoading,
                icon: Icons.admin_panel_settings_outlined,
                onPressed: () async {
                  if (_emailCtrl.text.isEmpty) return;
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(authServiceProvider).grantAdmin(_emailCtrl.text.trim());
                    _emailCtrl.clear();
                    if (mounted) showSuccess(context, 'Admin access granted!');
                  } catch (e) {
                    if (mounted) showError(context, e.toString());
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Current Admins', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (admins.isEmpty)
            const Center(child: Text('No admins found'))
          else
            ...admins.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(children: [
                  UserAvatar(name: a.name, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 14, color: AppColors.ink)),
                      Text(a.email, style: const TextStyle(
                          fontSize: 12, color: AppColors.slate)),
                    ],
                  )),
                  const StatusPill(label: 'ADMIN', color: AppColors.gold),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: AppColors.error, size: 20),
                    onPressed: () => ref.read(authServiceProvider).revokeAdmin(a.uid),
                  ),
                ]),
              ),
            )),
        ],
      ),
    );
  }
}
