import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN SHELL — 9 tabs
// ═══════════════════════════════════════════════════════════════════════════════
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabs = [
    ('📊', 'Overview'),
    ('🏟', 'Grounds'),
    ('🚫', 'Slots'),
    ('📅', 'Bookings'),
    ('📣', 'News'),
    ('💰', 'Funds'),
    ('💬', 'Feedback'),
    ('📞', 'Contacts'),
    ('👤', 'Admins'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (!_tab.indexIsChanging) {
      ref.read(adminTabIndexProvider.notifier).state = _tab.index;
    }
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChange);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Navigate to Overview when MainShell resets the tab index to 0
    ref.listen<int>(adminTabIndexProvider, (prev, next) {
      if (next == 0 && _tab.index != 0) {
        _tab.animateTo(0);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Admin Panel ⚙️'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.mint,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.mint,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: '${t.$1} ${t.$2}')).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(tabController: _tab),
          const _GroundsTab(),
          const _BlockSlotsTab(),
          const _BookingsTab(),
          const _NewsTab(),
          const _FundsTab(),
          const _FeedbackTab(),
          const _ContactsTab(),
          const _AdminsTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 0. OVERVIEW TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends ConsumerWidget {
  final TabController tabController;
  const _OverviewTab({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grounds   = ref.watch(allGroundsProvider).valueOrNull ?? [];
    final bookings  = ref.watch(allBookingsProvider).valueOrNull ?? [];
    final news      = ref.watch(newsProvider).valueOrNull ?? [];
    final funds     = ref.watch(fundraisersProvider).valueOrNull ?? [];
    final feedbacks = ref.watch(feedbackProvider).valueOrNull ?? [];
    final user      = ref.watch(currentAppUserProvider).valueOrNull;

    final today = DateTime.now();
    final todayBookings = bookings.where((b) =>
      b.date.year == today.year &&
      b.date.month == today.month &&
      b.date.day == today.day &&
      b.status == BookingStatus.confirmed).toList();
    final pendingFeedback = feedbacks.where((f) => !f.isResolved).length;
    final activeFunds = funds.where((f) => f.isActive).length;
    final recentBookings = bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back,', style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 13)),
              const SizedBox(height: 2),
              Text(user?.name ?? 'Admin', style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(DateFormat('EEEE, d MMMM y').format(today),
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Stat grid ───────────────────────────────────────────────────
          const _SectionLabel('At a Glance'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'Today\'s Bookings',
                value: '${todayBookings.length}',
                icon: Icons.today_outlined,
                color: AppColors.mint,
                onTap: () => tabController.animateTo(3),
              ),
              _StatCard(
                label: 'Total Bookings',
                value: '${bookings.length}',
                icon: Icons.calendar_month_outlined,
                color: AppColors.info,
                onTap: () => tabController.animateTo(3),
              ),
              _StatCard(
                label: 'Grounds',
                value: '${grounds.length}',
                icon: Icons.sports_outlined,
                color: AppColors.green,
                onTap: () => tabController.animateTo(1),
              ),
              _StatCard(
                label: 'Pending Feedback',
                value: '$pendingFeedback',
                icon: Icons.feedback_outlined,
                color: pendingFeedback > 0 ? AppColors.warning : AppColors.slate,
                onTap: () => tabController.animateTo(6),
              ),
              _StatCard(
                label: 'News Posts',
                value: '${news.length}',
                icon: Icons.campaign_outlined,
                color: AppColors.gold,
                onTap: () => tabController.animateTo(4),
              ),
              _StatCard(
                label: 'Active Funds',
                value: '$activeFunds',
                icon: Icons.volunteer_activism_outlined,
                color: AppColors.error,
                onTap: () => tabController.animateTo(5),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Recent bookings ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Recent Bookings'),
              TextButton(
                onPressed: () => tabController.animateTo(3),
                child: const Text('See all', style: TextStyle(
                    color: AppColors.mint, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentBookings.isEmpty)
            const _EmptyHint('No bookings yet')
          else
            ...recentBookings.take(5).map((b) => _RecentBookingRow(booking: b)),
          const SizedBox(height: 24),

          // ── Active fundraisers ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Active Fundraisers'),
              TextButton(
                onPressed: () => tabController.animateTo(5),
                child: const Text('See all', style: TextStyle(
                    color: AppColors.mint, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (funds.where((f) => f.isActive).isEmpty)
            const _EmptyHint('No active fundraisers')
          else
            ...funds.where((f) => f.isActive).take(3).map((f) => _FundRow(fund: f)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(
                  fontSize: 11, color: AppColors.slate),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      ),
    );
  }
}

class _RecentBookingRow extends StatelessWidget {
  final Booking booking;
  const _RecentBookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Text(booking.groundIcon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.userName, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
          Text('${booking.groundName} · ${booking.slot}  '
              '${DateFormat('d MMM').format(booking.date)}',
              style: const TextStyle(fontSize: 11, color: AppColors.slate)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.mint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Confirmed',
              style: TextStyle(fontSize: 10, color: AppColors.mint,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _FundRow extends StatelessWidget {
  final Fundraiser fund;
  const _FundRow({required this.fund});

  @override
  Widget build(BuildContext context) {
    final pct = fund.progressPercent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(fund.title, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: AppColors.slate,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.mist,
            color: AppColors.mint,
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text('₹${fund.raisedAmount.toStringAsFixed(0)} raised of ₹${fund.goalAmount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11, color: AppColors.slate)),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink));
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.slate, fontSize: 13)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. GROUNDS TAB
// ═══════════════════════════════════════════════════════════════════════════════
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
        onPressed: () => _showAddGroundSheet(context, ref),
      ),
      body: grounds.isEmpty
          ? const EmptyState(emoji: '🏟', title: 'No grounds yet',
              subtitle: 'Tap + to add your first play area')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: grounds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _GroundAdminCard(ground: grounds[i], allGrounds: grounds)
                      .animate().fadeIn(delay: (i * 60).ms),
            ),
    );
  }

  void _showAddGroundSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String icon  = '🏟';
    String color = '#1A5C3A';
    final slots  = ['06:00','07:00','08:00','09:00','10:00',
                    '14:00','15:00','16:00','17:00','18:00','19:00'];
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            const Text('New Play Area', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 20),
            _Label('Icon'),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10,
              children: ['🏟','🏏','⚽','🏸',/*'🎾','🏐','🏑','🥊','🏊','🎱'*/].map((e) =>
                GestureDetector(onTap: () => setS(() => icon = e),
                  child: _IconOption(emoji: e, selected: icon == e)),
              ).toList(),
            ),
            const SizedBox(height: 16),
            _Label('Color'),
            const SizedBox(height: 8),
            Wrap(spacing: 10, children: {
              '#1A5C3A': AppColors.green, '#1A3A6C': const Color(0xFF1A3A6C),
              '#4A235A': const Color(0xFF4A235A), '#C0392B': const Color(0xFFC0392B),
              '#E8B84B': AppColors.gold, '#2C3E50': const Color(0xFF2C3E50),
            }.entries.map((e) => GestureDetector(onTap: () => setS(() => color = e.key),
              child: _ColorDot(hex: e.key, c: e.value, selected: color == e.key),
            )).toList()),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ground Name *')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create Ground', fullWidth: true, icon: Icons.add,
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                await ref.read(firestoreServiceProvider).addGround(PlayGround(
                  id: const Uuid().v4(), name: nameCtrl.text.trim(),
                  icon: icon, colorHex: color, timeSlots: slots,
                  description: descCtrl.text.trim(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              }),
          ],
        )),
      )),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(ground.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ground.name, style: const TextStyle(fontWeight: FontWeight.w700,
                fontSize: 16, color: AppColors.ink)),
            Text('${ground.timeSlots.length} slots · ${ground.blockedSlots.length} blocked · '
                '${ground.conflictIds.length} conflicts',
                style: const TextStyle(fontSize: 12, color: AppColors.slate)),
          ])),
          Switch(value: ground.isActive, activeColor: AppColors.mint,
              onChanged: (v) => ref.read(firestoreServiceProvider)
                  .updateGround(ground.copyWith(isActive: v))),
          IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.info),
              onPressed: () => _showEditGroundSheet(context, ref)),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, ref)),
        ]),
        const Divider(),
        _Label('Conflict Dependencies'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8,
          children: allGrounds.where((g) => g.id != ground.id).map((other) {
            final has = ground.conflictIds.contains(other.id);
            return GestureDetector(onTap: () => _toggleConflict(ref, other),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: has ? AppColors.error.withOpacity(0.1) : AppColors.mist,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: has ? AppColors.error : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(has ? Icons.link_off : Icons.link, size: 14,
                      color: has ? AppColors.error : AppColors.slate),
                  const SizedBox(width: 4),
                  Text('${other.icon} ${other.name}', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: has ? AppColors.error : AppColors.slate)),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  void _showEditGroundSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: ground.name);
    final descCtrl = TextEditingController(text: ground.description);
    String icon  = ground.icon;
    String color = ground.colorHex;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            const Text('Edit Play Area', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 20),
            _Label('Icon'),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10,
              children: ['🏟','🏏','⚽','🏸'].map((e) =>
                GestureDetector(onTap: () => setS(() => icon = e),
                  child: _IconOption(emoji: e, selected: icon == e)),
              ).toList(),
            ),
            const SizedBox(height: 16),
            _Label('Color'),
            const SizedBox(height: 8),
            Wrap(spacing: 10, children: {
              '#1A5C3A': AppColors.green, '#1A3A6C': const Color(0xFF1A3A6C),
              '#4A235A': const Color(0xFF4A235A), '#C0392B': const Color(0xFFC0392B),
              '#E8B84B': AppColors.gold, '#2C3E50': const Color(0xFF2C3E50),
            }.entries.map((e) => GestureDetector(
              onTap: () => setS(() => color = e.key),
              child: _ColorDot(hex: e.key, c: e.value, selected: color == e.key),
            )).toList()),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ground Name *')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)')),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save Changes',
              fullWidth: true,
              icon: Icons.check_outlined,
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                await ref.read(firestoreServiceProvider).updateGround(
                  ground.copyWith(
                    name: nameCtrl.text.trim(),
                    icon: icon,
                    colorHex: color,
                    description: descCtrl.text.trim(),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        )),
      )),
    );
  }

  Future<void> _toggleConflict(WidgetRef ref, PlayGround other) async {
    final fs  = ref.read(firestoreServiceProvider);
    final has = ground.conflictIds.contains(other.id);
    final ids = has ? ground.conflictIds.where((x) => x != other.id).toList()
                    : [...ground.conflictIds, other.id];
    await fs.updateConflicts(ground.id, ids);
    final otherHas = other.conflictIds.contains(ground.id);
    if (has && otherHas) {
      await fs.updateConflicts(other.id, other.conflictIds.where((x) => x != ground.id).toList());
    } else if (!has && !otherHas) {
      await fs.updateConflicts(other.id, [...other.conflictIds, ground.id]);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Ground?'),
      content: Text('Delete "${ground.name}"? This cannot be undone.'),
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

// ═══════════════════════════════════════════════════════════════════════════════
// 2. BLOCK SLOTS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _BlockSlotsTab extends ConsumerStatefulWidget {
  const _BlockSlotsTab();

  @override
  ConsumerState<_BlockSlotsTab> createState() => _BlockSlotsTabState();
}

class _BlockSlotsTabState extends ConsumerState<_BlockSlotsTab> {
  PlayGround? _sel;
  final _addCtrl = TextEditingController();

  @override
  void dispose() { _addCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final grounds = ref.watch(allGroundsProvider).valueOrNull ?? [];
    if (_sel == null && grounds.isNotEmpty) _sel = grounds.first;
    if (_sel != null && grounds.isNotEmpty) {
      _sel = grounds.firstWhere((g) => g.id == _sel!.id, orElse: () => grounds.first);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label('Select Ground'),
        const SizedBox(height: 10),
        grounds.isEmpty
            ? const Text('No grounds configured')
            : Wrap(spacing: 8, runSpacing: 8,
                children: grounds.map((g) {
                  final isSel = _sel?.id == g.id;
                  final c = hexToColor(g.colorHex);
                  return GestureDetector(onTap: () => setState(() => _sel = g),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? c.withOpacity(0.1) : AppColors.mist,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? c : AppColors.border,
                            width: isSel ? 2 : 1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(g.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(g.name, style: TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 13, color: isSel ? c : AppColors.slate)),
                      ]),
                    ),
                  );
                }).toList()),
        if (_sel != null) ...[
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: Text('Time Slots', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink))),
            _LegendDot(color: AppColors.mist, border: AppColors.border, label: 'Available'),
            const SizedBox(width: 12),
            _LegendDot(color: AppColors.warning.withOpacity(0.15),
                border: AppColors.warning, label: 'Blocked'),
          ]),
          const SizedBox(height: 6),
          const Text('Tap to toggle', style: TextStyle(fontSize: 12, color: AppColors.slate)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8,
            children: _sel!.timeSlots.map((slot) {
              final isBlocked = _sel!.blockedSlots.contains(slot);
              return GestureDetector(
                onTap: () async {
                  final fs = ref.read(firestoreServiceProvider);
                  isBlocked ? await fs.unblockSlot(_sel!.id, slot)
                            : await fs.blockSlot(_sel!.id, slot);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isBlocked ? AppColors.warning.withOpacity(0.1) : AppColors.mist,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isBlocked ? AppColors.warning : AppColors.border,
                        width: isBlocked ? 2 : 1)),
                  alignment: Alignment.center,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(slot, style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 14, color: isBlocked ? AppColors.warning : AppColors.ink)),
                    if (isBlocked) const Text('BLOCKED', style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.warning)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _Label('Manage Time Slots'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _addCtrl,
                decoration: const InputDecoration(labelText: 'Add slot (HH:MM)',
                    prefixIcon: Icon(Icons.add_alarm_outlined)))),
            const SizedBox(width: 10),
            PrimaryButton(label: 'Add', onPressed: () async {
              final slot = _addCtrl.text.trim();
              if (slot.isEmpty || _sel == null) return;
              final updated = {..._sel!.timeSlots, slot}.toList()..sort();
              await ref.read(firestoreServiceProvider)
                  .updateGround(_sel!.copyWith(timeSlots: updated));
              _addCtrl.clear();
            }),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8,
            children: _sel!.timeSlots.map((slot) => Chip(
              label: Text(slot, style: const TextStyle(fontSize: 13, color:AppColors.ink)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () async {
                final updated = _sel!.timeSlots.where((s) => s != slot).toList();
                await ref.read(firestoreServiceProvider)
                    .updateGround(_sel!.copyWith(timeSlots: updated));
              },
              backgroundColor: AppColors.mist,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border)),
            )).toList()),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. BOOKINGS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab();

  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab> {
  String _status = 'all';
  String? _groundId;
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider);
    final grounds = ref.watch(allGroundsProvider).valueOrNull ?? [];

    return Column(children: [
      // ── Filter bar ──
      Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final (val, lbl) in [('all','All'),('confirmed','Confirmed'),('cancelled','Cancelled')])
                Padding(padding: const EdgeInsets.only(right: 8),
                  child: _Chip(label: lbl, active: _status == val,
                      onTap: () => setState(() => _status = val))),
              // Date picker
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context,
                      initialDate: _date ?? DateTime.now(),
                      firstDate: DateTime(2024), lastDate: DateTime(2030));
                  setState(() => _date = d);
                },
                child: _DateChip(date: _date, onClear: () => setState(() => _date = null)),
              ),
              const SizedBox(width: 8),
              // Ground dropdown
              if (grounds.isNotEmpty)
                DropdownButton<String?>(
                  value: _groundId,
                  isDense: true,
                  underline: const SizedBox(),
                  hint: const Text('Ground', style: TextStyle(fontSize: 12, color: AppColors.slate)),
                  style: const TextStyle(fontSize: 12, color: AppColors.ink, fontFamily: 'Outfit'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All grounds')),
                    ...grounds.map((g) => DropdownMenuItem(value: g.id,
                        child: Text('${g.icon} ${g.name}'))),
                  ],
                  onChanged: (v) => setState(() => _groundId = v),
                ),
            ]),
          ),
        ]),
      ),

      // ── List ──
      Expanded(child: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(emoji: '⚠️', title: 'Failed',
            subtitle: 'Please try again'),
        data: (all) {
          final list = all.where((b) {
            if (_status != 'all' && b.status.name != _status) return false;
            if (_groundId != null && b.groundId != _groundId) return false;
            if (_date != null) {
              final d = b.date;
              if (d.year != _date!.year || d.month != _date!.month || d.day != _date!.day) return false;
            }
            return true;
          }).toList();

          if (list.isEmpty) return const EmptyState(emoji: '📅',
              title: 'No bookings found', subtitle: 'Try changing filters');

          final confirmed = list.where((b) => b.status == BookingStatus.confirmed).length;
          final cancelled = list.where((b) => b.status == BookingStatus.cancelled).length;

          return Column(children: [
            // Stats strip
            Container(color: AppColors.mist,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _StatBadge('${list.length} total', AppColors.slate),
                  const SizedBox(width: 8),
                  _StatBadge('$confirmed confirmed', AppColors.mint),
                  if (cancelled > 0) ...[
                    const SizedBox(width: 8),
                    _StatBadge('$cancelled cancelled', AppColors.error),
                  ],
                ]),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _BookingAdminCard(
                  booking: list[i],
                  onCancel: list[i].status == BookingStatus.confirmed
                      ? () => _cancelDialog(context, ref, list[i]) : null,
                ).animate().fadeIn(delay: (i * 40).ms),
              ),
            ),
          ]);
        },
      )),
    ]);
  }

  void _cancelDialog(BuildContext context, WidgetRef ref, Booking b) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cancel Booking?'),
      content: Text('Cancel ${b.groundName} for ${b.userName} on '
          '${DateFormat('d MMM').format(b.date)} at ${b.slot}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
        ElevatedButton(
          onPressed: () async {
            await ref.read(firestoreServiceProvider).cancelBooking(b.id);
            if (ctx.mounted) { Navigator.pop(ctx); showSuccess(context, 'Booking cancelled'); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Cancel Booking'),
        ),
      ],
    ),
  );
}

class _BookingAdminCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  const _BookingAdminCard({required this.booking, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final ok   = booking.status == BookingStatus.confirmed;
    final past = booking.date.isBefore(DateTime.now());
    return AppCard(
      borderColor: ok ? AppColors.mint.withOpacity(0.3) : AppColors.border,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.mint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(booking.groundIcon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.groundName, style: const TextStyle(fontWeight: FontWeight.w700,
                fontSize: 15, color: AppColors.ink)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.slate),
              const SizedBox(width: 4),
              Text(DateFormat('EEE, d MMM yyyy').format(booking.date),
                  style: const TextStyle(fontSize: 12, color: AppColors.slate)),
              const SizedBox(width: 10),
              const Icon(Icons.access_time_outlined, size: 12, color: AppColors.slate),
              const SizedBox(width: 4),
              Text(booking.slot, style: const TextStyle(fontSize: 12,
                  color: AppColors.slate, fontWeight: FontWeight.w600)),
            ]),
          ])),
          StatusPill(
            label: ok ? (past ? 'Done' : 'Confirmed') : 'Cancelled',
            color: ok ? (past ? AppColors.slate : AppColors.mint) : AppColors.error,
          ),
        ]),
        const Divider(height: 16),
        Row(children: [
          UserAvatar(name: booking.userName, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.userName, style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 13, color: AppColors.ink)),
            if (booking.userPhone.isNotEmpty)
              Text(booking.userPhone,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate)),
          ])),
          if (booking.userPhone.isNotEmpty)
            _IconBtn(icon: Icons.phone_outlined, color: AppColors.mint,
                onTap: () async {
                  final url = Uri.parse('tel:${booking.userPhone}');
                  if (await canLaunchUrl(url)) {
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }),
          const SizedBox(width: 6),
          if (onCancel != null && !past)
            _IconBtn(icon: Icons.cancel_outlined, color: AppColors.error, onTap: onCancel!),
          const SizedBox(width: 6),
          Text(DateFormat('d MMM, h:mm a').format(booking.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.slate)),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. NEWS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _NewsTab extends ConsumerStatefulWidget {
  const _NewsTab();

  @override
  ConsumerState<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends ConsumerState<_NewsTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  File? _image;
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(currentAppUserProvider).valueOrNull;
    final newsList  = ref.watch(newsProvider).valueOrNull ?? [];

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Post News'),
        const SizedBox(height: 12),
        AppCard(child: Column(children: [
          TextField(controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Headline *')),
          const SizedBox(height: 12),
          TextField(controller: _bodyCtrl, maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content *',
                  alignLabelWithHint: true)),
          const SizedBox(height: 12),
          GestureDetector(onTap: () async {
            final x = await ImagePicker().pickImage(
                source: ImageSource.gallery, imageQuality: 75);
            if (x != null) setState(() => _image = File(x.path));
          }, child: Container(height: _image != null ? 160 : 56, width: double.infinity,
            decoration: BoxDecoration(color: AppColors.mist,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            clipBehavior: Clip.antiAlias,
            child: _image != null
              ? Stack(fit: StackFit.expand, children: [
                  Image.file(_image!, fit: BoxFit.cover),
                  Positioned(top: 8, right: 8, child: GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14)),
                  )),
                ])
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.slate, size: 20),
                  SizedBox(width: 8),
                  Text('Attach image (optional)',
                      style: TextStyle(color: AppColors.slate, fontSize: 13)),
                ]),
          )),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Publish News', fullWidth: true, isLoading: _loading,
            icon: Icons.campaign_outlined,
            onPressed: () async {
              if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
              setState(() => _loading = true);
              await ref.read(firestoreServiceProvider).addNews(
                title: _titleCtrl.text.trim(), body: _bodyCtrl.text.trim(),
                authorId: user!.uid, authorName: user.name, imageFile: _image,
              );
              _titleCtrl.clear(); _bodyCtrl.clear();
              setState(() { _loading = false; _image = null; });
              if (mounted) showSuccess(context, 'News published!');
            }),
        ])),
        if (newsList.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Label('Published (${newsList.length})'),
          const SizedBox(height: 12),
          ...newsList.map((n) => Container(margin: const EdgeInsets.only(bottom: 10),
            child: AppCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (n.imageUrl != null)
                ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(imageUrl: n.imageUrl!,
                      width: 56, height: 56, fit: BoxFit.cover)),
              if (n.imageUrl != null) const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 13, color: AppColors.ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(DateFormat('d MMM · h:mm a').format(n.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                Row(children: [
                  const Icon(Icons.favorite, size: 11, color: AppColors.error),
                  const SizedBox(width: 3),
                  Text('${n.likeCount}', style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                ]),
              ])),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => ref.read(firestoreServiceProvider).deleteNews(n.id)),
            ])),
          )),
        ],
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. FUNDS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _FundsTab extends ConsumerStatefulWidget {
  const _FundsTab();

  @override
  ConsumerState<_FundsTab> createState() => _FundsTabState();
}

class _FundsTabState extends ConsumerState<_FundsTab> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _goalCtrl     = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _goalCtrl.dispose(); _deadlineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final funds = ref.watch(fundraisersProvider).valueOrNull ?? [];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Create Campaign'),
        const SizedBox(height: 12),
        AppCard(child: Column(children: [
          TextField(controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Campaign Title *')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description',
                  alignLabelWithHint: true)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _goalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Goal (₹)',
                    prefixIcon: Icon(Icons.currency_rupee)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _deadlineCtrl,
                decoration: const InputDecoration(labelText: 'Deadline',
                    hintText: 'Dec 2025'))),
          ]),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Create Campaign', fullWidth: true, isLoading: _loading,
            icon: Icons.add, color: AppColors.gold,
            onPressed: () async {
              if (_titleCtrl.text.isEmpty || _goalCtrl.text.isEmpty) return;
              setState(() => _loading = true);
              await ref.read(firestoreServiceProvider).addFundraiser(Fundraiser(
                id: const Uuid().v4(), title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim(),
                goalAmount: double.tryParse(_goalCtrl.text) ?? 0,
                deadline: _deadlineCtrl.text.trim(), createdAt: DateTime.now(),
              ));
              _titleCtrl.clear(); _descCtrl.clear(); _goalCtrl.clear(); _deadlineCtrl.clear();
              if (mounted) { setState(() => _loading = false); showSuccess(context, 'Campaign created!'); }
            }),
        ])),
        if (funds.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Label('Campaigns (${funds.length})'),
          const SizedBox(height: 12),
          ...funds.map((f) => Container(margin: const EdgeInsets.only(bottom: 10),
            child: AppCard(child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.title, style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppColors.ink)),
                  Text('Goal ₹${f.goalAmount.toStringAsFixed(0)} · ${f.deadline}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                ])),
                Switch(value: f.isActive, activeColor: AppColors.mint,
                    onChanged: (v) => ref.read(firestoreServiceProvider)
                        .updateFundraiser(f.id, {'isActive': v})),
              ]),
              const SizedBox(height: 8),
              FundProgressBar(progress: f.progressPercent),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('₹${f.raisedAmount.toStringAsFixed(0)} raised',
                    style: const TextStyle(fontSize: 12, color: AppColors.mint,
                        fontWeight: FontWeight.w600)),
                Text('${(f.progressPercent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate)),
              ]),
            ])))),
        ],
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. FEEDBACK TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _FeedbackTab extends ConsumerStatefulWidget {
  const _FeedbackTab();

  @override
  ConsumerState<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends ConsumerState<_FeedbackTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackProvider);

    return Column(children: [
      Container(color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final (val, lbl) in [
              ('all','All'), ('suggestion','💡 Suggestions'),
              ('complaint','⚠️ Complaints'), ('unresolved','🔴 Unresolved'),
              ('resolved','✅ Resolved'),
            ])
              Padding(padding: const EdgeInsets.only(right: 8),
                child: _Chip(label: lbl, active: _filter == val,
                    onTap: () => setState(() => _filter = val))),
          ]),
        ),
      ),
      Expanded(child: feedbackAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(emoji: '⚠️', title: 'Error', subtitle: 'Try again'),
        data: (all) {
          final list = all.where((f) {
            switch (_filter) {
              case 'suggestion':  return f.type == FeedbackType.suggestion;
              case 'complaint':   return f.type == FeedbackType.complaint;
              case 'unresolved':  return !f.isResolved;
              case 'resolved':    return f.isResolved;
              default:            return true;
            }
          }).toList();

          if (list.isEmpty) return EmptyState(emoji: '💬',
              title: 'No ${_filter == 'all' ? '' : _filter} feedback',
              subtitle: 'Nothing to show');

          return Column(children: [
            Container(color: AppColors.mist,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _StatBadge('${all.length} total', AppColors.slate),
                  const SizedBox(width: 8),
                  _StatBadge('${all.where((f) => f.type == FeedbackType.suggestion).length} suggestions',
                      AppColors.info),
                  const SizedBox(width: 8),
                  _StatBadge('${all.where((f) => f.type == FeedbackType.complaint).length} complaints',
                      AppColors.warning),
                  const SizedBox(width: 8),
                  _StatBadge('${all.where((f) => !f.isResolved).length} open', AppColors.error),
                ]),
              ),
            ),
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _FeedbackCard(item: list[i])
                  .animate().fadeIn(delay: (i * 40).ms),
            )),
          ]);
        },
      )),
    ]);
  }
}

class _FeedbackCard extends ConsumerWidget {
  final ClubFeedback item;
  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSugg = item.type == FeedbackType.suggestion;
    final typeColor = isSugg ? AppColors.info : AppColors.warning;

    return AppCard(
      borderColor: item.isResolved ? AppColors.border : typeColor.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Type + status
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withOpacity(0.4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(isSugg ? '💡' : '⚠️', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(isSugg ? 'Suggestion' : 'Complaint', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: typeColor)),
            ]),
          ),
          const Spacer(),
          StatusPill(label: item.isResolved ? '✅ Resolved' : '🔴 Open',
              color: item.isResolved ? AppColors.mint : AppColors.error),
        ]),
        const SizedBox(height: 12),
        // Sender info
        Row(children: [
          UserAvatar(name: item.userName, size: 30),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.userName, style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 13, color: AppColors.ink)),
            Text(DateFormat('d MMM yyyy, h:mm a').format(item.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.slate)),
          ])),
        ]),
        const SizedBox(height: 10),
        // Message
        Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.mist,
              borderRadius: BorderRadius.circular(10)),
          child: Text(item.message, style: const TextStyle(
              fontSize: 13, color: AppColors.ink, height: 1.5)),
        ),
        // Attached image
        if (item.imageUrl != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              child: GestureDetector(onTap: () => Navigator.pop(ctx),
                child: ClipRRect(borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(imageUrl: item.imageUrl!,
                      fit: BoxFit.contain))),
            )),
            child: ClipRRect(borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: item.imageUrl!,
                  height: 160, width: double.infinity, fit: BoxFit.cover)),
          ),
        ],
        const SizedBox(height: 12),
        if (!item.isResolved)
          PrimaryButton(label: 'Mark Resolved', fullWidth: true,
            icon: Icons.check_circle_outline,
            onPressed: () async {
              await ref.read(firestoreServiceProvider).resolveFeedback(item.id);
              if (context.mounted) showSuccess(context, 'Marked as resolved');
            })
        else
          const Row(children: [
            Icon(Icons.check_circle, color: AppColors.mint, size: 16),
            SizedBox(width: 6),
            Text('Resolved', style: TextStyle(color: AppColors.mint,
                fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. CONTACTS TAB — full CRUD
// ═══════════════════════════════════════════════════════════════════════════════
class _ContactsTab extends ConsumerWidget {
  const _ContactsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider).valueOrNull ?? [];
    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mint, foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined), label: const Text('Add Contact'),
        onPressed: () => _openSheet(context, ref, null),
      ),
      body: contacts.isEmpty
          ? const EmptyState(emoji: '📞', title: 'No contacts yet',
              subtitle: 'Tap + to add your first quick contact')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ContactAdminCard(
                contact: contacts[i],
                onEdit: () => _openSheet(context, ref, contacts[i]),
                onDelete: () => _confirmDelete(context, ref, contacts[i]),
              ).animate().fadeIn(delay: (i * 50).ms),
            ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, QuickContact? existing) =>
      showModalBottomSheet(
        context: context, isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _ContactSheet(existing: existing, ref: ref),
      );

  void _confirmDelete(BuildContext context, WidgetRef ref, QuickContact c) =>
      showDialog(context: context, builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Contact?'),
        content: Text('Remove "${c.name}" from quick contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).deleteContact(c.id);
              if (ctx.mounted) { Navigator.pop(ctx); showSuccess(context, 'Contact deleted'); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ));
}

class _ContactAdminCard extends StatelessWidget {
  final QuickContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ContactAdminCard({required this.contact, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(children: [
      UserAvatar(name: contact.name, size: 48),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w700,
            fontSize: 15, color: AppColors.ink)),
        Text(contact.role, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.phone_outlined, size: 12, color: AppColors.mint),
          const SizedBox(width: 4),
          Text(contact.phone, style: const TextStyle(fontSize: 13,
              color: AppColors.mint, fontWeight: FontWeight.w600)),
        ]),
      ])),
      Column(children: [
        _IconBtn(icon: Icons.edit_outlined, color: AppColors.info, onTap: onEdit),
        const SizedBox(height: 8),
        _IconBtn(icon: Icons.delete_outline, color: AppColors.error, onTap: onDelete),
      ]),
    ]),
  );
}

class _ContactSheet extends StatefulWidget {
  final QuickContact? existing;
  final WidgetRef ref;
  const _ContactSheet({required this.existing, required this.ref});

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _phone = TextEditingController();
  final _role  = TextEditingController();
  final _order = TextEditingController();
  bool _loading = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _name.text  = widget.existing!.name;
      _phone.text = widget.existing!.phone;
      _role.text  = widget.existing!.role;
      _order.text = widget.existing!.sortOrder.toString();
    }
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _role.dispose(); _order.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fs = widget.ref.read(firestoreServiceProvider);
      final c = QuickContact(
        id: _isEdit ? widget.existing!.id : const Uuid().v4(),
        name: _name.text.trim(), phone: _phone.text.trim(),
        role: _role.text.trim(), sortOrder: int.tryParse(_order.text) ?? 0,
      );
      if (_isEdit) { await fs.deleteContact(c.id); }
      await fs.addContact(c);
      if (mounted) {
        Navigator.pop(context);
        showSuccess(context, _isEdit ? 'Contact updated!' : 'Contact added!');
      }
    } catch (e) {
      if (mounted) showError(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24),
    child: Form(key: _formKey, child: SingleChildScrollView(child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetHandle(),
        const SizedBox(height: 20),
        Text(_isEdit ? 'Edit Contact ✏️' : 'New Contact ➕',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 20),
        TextFormField(controller: _name,
          decoration: const InputDecoration(labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person_outline)),
          validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number *',
              prefixIcon: Icon(Icons.phone_outlined), hintText: '+91 98765 43210'),
          validator: (v) => (v == null || v.isEmpty) ? 'Phone required' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _role,
          decoration: const InputDecoration(labelText: 'Role / Department *',
              prefixIcon: Icon(Icons.work_outline), hintText: 'e.g. Ground Manager'),
          validator: (v) => (v == null || v.isEmpty) ? 'Role required' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _order, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Sort Order (0 = first)',
              prefixIcon: Icon(Icons.sort_outlined))),
        const SizedBox(height: 24),
        PrimaryButton(label: _isEdit ? 'Update Contact' : 'Add Contact',
          fullWidth: true, isLoading: _loading,
          icon: _isEdit ? Icons.save_outlined : Icons.person_add_outlined,
          onPressed: _save),
      ],
    ))),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 8. ADMINS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _AdminsTab extends ConsumerStatefulWidget {
  const _AdminsTab();

  @override
  ConsumerState<_AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends ConsumerState<_AdminsTab> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final admins = ref.watch(adminUsersProvider).valueOrNull ?? [];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Grant Admin Access'),
        const SizedBox(height: 12),
        AppCard(child: Column(children: [
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'User Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                prefixText: '+91  ')),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Grant Admin', fullWidth: true, isLoading: _loading,
            icon: Icons.admin_panel_settings_outlined,
            onPressed: () async {
              if (_phoneCtrl.text.isEmpty) return;
              setState(() => _loading = true);
              try {
                final phone = _phoneCtrl.text.trim();
                final fullPhone = phone.startsWith('+') ? phone : '+91$phone';
                await ref.read(authServiceProvider).grantAdminByPhone(fullPhone);
                _phoneCtrl.clear();
                if (mounted) showSuccess(context, 'Admin access granted!');
              } catch (e) {
                if (mounted) showError(context, e.toString());
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            }),
        ])),
        const SizedBox(height: 24),
        _Label('Current Admins (${admins.length})'),
        const SizedBox(height: 12),
        if (admins.isEmpty) const Center(child: Text('No admins found'))
        else ...admins.map((a) => Container(margin: const EdgeInsets.only(bottom: 10),
          child: AppCard(child: Row(children: [
            UserAvatar(name: a.name, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 14, color: AppColors.ink)),
              Text(a.phone.isNotEmpty ? a.phone : '—',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate)),
            ])),
            const StatusPill(label: 'ADMIN', color: AppColors.gold),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.person_remove_outlined,
                color: AppColors.error, size: 20),
                onPressed: () => ref.read(authServiceProvider).revokeAdmin(a.uid)),
          ])))),
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TINY LOCAL HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.mint : AppColors.mist,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.mint : AppColors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.slate)),
    ),
  );
}

class _DateChip extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onClear;
  const _DateChip({required this.date, required this.onClear});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: date != null ? AppColors.mint.withOpacity(0.1) : AppColors.mist,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: date != null ? AppColors.mint : AppColors.border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.calendar_today_outlined, size: 13,
          color: date != null ? AppColors.mint : AppColors.slate),
      const SizedBox(width: 5),
      Text(date != null ? DateFormat('d MMM').format(date!) : 'Date',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: date != null ? AppColors.mint : AppColors.slate)),
      if (date != null) ...[
        const SizedBox(width: 4),
        GestureDetector(onTap: onClear,
          child: Icon(Icons.close, size: 13, color: AppColors.mint)),
      ],
    ]),
  );
}

Widget _StatBadge(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3))),
  child: Text(label, style: TextStyle(fontSize: 11,
      fontWeight: FontWeight.w700, color: color)),
);

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 16)),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color, border;
  final String label;
  const _LegendDot({required this.color, required this.border, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color,
        borderRadius: BorderRadius.circular(3), border: Border.all(color: border))),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate)),
  ]);
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(width: 40, height: 4,
        decoration: BoxDecoration(color: AppColors.border,
            borderRadius: BorderRadius.circular(2))),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
      fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink));
}

class _IconOption extends StatelessWidget {
  final String emoji;
  final bool selected;
  const _IconOption({required this.emoji, required this.selected});

  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: selected ? AppColors.mint.withOpacity(0.15) : AppColors.mist,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: selected ? AppColors.mint : AppColors.border,
          width: selected ? 2 : 1)),
    alignment: Alignment.center,
    child: Text(emoji, style: const TextStyle(fontSize: 22)),
  );
}

class _ColorDot extends StatelessWidget {
  final String hex;
  final Color c;
  final bool selected;
  const _ColorDot({required this.hex, required this.c, required this.selected});

  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 3)),
    alignment: Alignment.center,
    child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
  );
}
