import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

// ─── Step 1: Pick Ground ──────────────────────────────────────────────────────
class BookGroundScreen extends ConsumerWidget {
  const BookGroundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grounds = ref.watch(groundsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Slot 🏅')),
      backgroundColor: AppColors.cream,
      body: grounds.isEmpty
          ? const EmptyState(
              emoji: '🏟', title: 'No grounds available',
              subtitle: 'Admin will add play areas soon',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: grounds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final g = grounds[i];
                return _GroundCard(ground: g)
                    .animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.05);
              },
            ),
    );
  }
}

class _GroundCard extends ConsumerWidget {
  final PlayGround ground;
  const _GroundCard({required this.ground});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = hexToColor(ground.colorHex);
    return AppCard(
      onTap: () {
        ref.read(selectedGroundProvider.notifier).state = ground;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const BookSlotScreen(),
        ));
      },
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(ground.icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ground.name,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 16, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('${ground.timeSlots.length} time slots available',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                if (ground.conflictIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('Shares slots with ${ground.conflictIds.length} ground(s)',
                          style: const TextStyle(fontSize: 11, color: AppColors.warning,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                if (ground.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(ground.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.slate),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    );
  }
}

// ─── Step 2: Pick Date & Slot ─────────────────────────────────────────────────
class BookSlotScreen extends ConsumerStatefulWidget {
  const BookSlotScreen({super.key});

  @override
  ConsumerState<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends ConsumerState<BookSlotScreen> {
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final ground = ref.watch(selectedGroundProvider);
    final selectedDate = ref.watch(selectedBookingDateProvider);
    final takenAsync = ref.watch(takenSlotsProvider);
    final color = ground != null ? hexToColor(ground.colorHex) : AppColors.mint;

    if (ground == null) return const Scaffold(body: Center(child: Text('No ground selected')));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('${ground.icon} ${ground.name}'),
        backgroundColor: color,
      ),
      body: Column(
        children: [
          // Date picker strip
          Container(
            color: color,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _DateStrip(
              selected: selectedDate,
              onChanged: (d) {
                ref.read(selectedBookingDateProvider.notifier).state = d;
                setState(() => _selectedSlot = null);
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Available Slots',
                          style: TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 16, color: AppColors.ink)),
                      const Spacer(),
                      _Legend(color: AppColors.mint, label: 'Free'),
                      const SizedBox(width: 12),
                      _Legend(color: AppColors.error, label: 'Taken'),
                      const SizedBox(width: 12),
                      _Legend(color: AppColors.warning, label: 'Blocked'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  takenAsync.when(
                    loading: () => GridView.count(
                      crossAxisCount: 3, shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8,
                      children: List.generate(6, (_) => const ShimmerBox(height: 52)),
                    ),
                    error: (_, __) => const Text('Failed to load slots'),
                    data: (takenSlots) {
                      return GridView.count(
                        crossAxisCount: 3, shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10, mainAxisSpacing: 10,
                        childAspectRatio: 1.8,
                        children: ground.timeSlots.map((slot) {
                          final isTaken = takenSlots.contains(slot) &&
                              !ground.blockedSlots.contains(slot);
                          final isBlocked = ground.blockedSlots.contains(slot);
                          return SlotChip(
                            time: slot,
                            isSelected: _selectedSlot == slot,
                            isTaken: isTaken,
                            isBlocked: isBlocked,
                            onTap: () => setState(() => _selectedSlot = slot),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom confirm bar
          if (_selectedSlot != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                    blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE, d MMMM').format(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 15, color: AppColors.ink),
                        ),
                        Text(_selectedSlot!,
                            style: const TextStyle(color: AppColors.slate, fontSize: 13)),
                      ],
                    ),
                  ),
                  PrimaryButton(
                    label: 'Continue →',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BookConfirmScreen(
                        ground: ground,
                        date: selectedDate,
                        slot: _selectedSlot!,
                      ),
                    )),
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, duration: 300.ms),
        ],
      ),
    );
  }
}

// ─── Date Strip ───────────────────────────────────────────────────────────────
class _DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _DateStrip({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              DateFormat('MMMM yyyy').format(selected),
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selected,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 60)),
                );
                if (picked != null) onChanged(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Pick date', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = days[i];
              final isSelected = DateFormat('yyyy-MM-dd').format(day) ==
                  DateFormat('yyyy-MM-dd').format(selected);
              return GestureDetector(
                onTap: () => onChanged(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(day),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.forest : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.forest : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.slate)),
      ],
    );
  }
}

// ─── Step 3: Confirm ──────────────────────────────────────────────────────────
class BookConfirmScreen extends ConsumerStatefulWidget {
  final PlayGround ground;
  final DateTime date;
  final String slot;

  const BookConfirmScreen({
    super.key,
    required this.ground,
    required this.date,
    required this.slot,
  });

  @override
  ConsumerState<BookConfirmScreen> createState() => _BookConfirmScreenState();
}

class _BookConfirmScreenState extends ConsumerState<BookConfirmScreen> {
  bool _isLoading = false;

  Future<void> _confirm() async {
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final booking = Booking(
        id: '',
        groundId: widget.ground.id,
        groundName: widget.ground.name,
        groundIcon: widget.ground.icon,
        slot: widget.slot,
        date: widget.date,
        userId: user.uid,
        userName: user.name,
        userPhone: user.phone,
        createdAt: DateTime.now(),
      );
      final id = await ref.read(firestoreServiceProvider).createBooking(booking);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            booking: Booking(
              id: id, groundId: booking.groundId, groundName: booking.groundName,
              groundIcon: booking.groundIcon, slot: booking.slot, date: booking.date,
              userId: booking.userId, userName: booking.userName,
              userPhone: booking.userPhone, createdAt: booking.createdAt,
            ),
          ),
        ));
      }
    } catch (e) {
      if (mounted) showError(context, 'Booking failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(widget.ground.colorHex);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking'), backgroundColor: color),
      backgroundColor: AppColors.cream,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(24),
              borderColor: AppColors.mint,
              borderWidth: 2,
              child: Column(
                children: [
                  Text(widget.ground.icon, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 8),
                  Text(widget.ground.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: 20),
                  const Divider(),
                  _ConfirmRow(icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: DateFormat('EEEE, d MMMM yyyy').format(widget.date)),
                  const Divider(),
                  _ConfirmRow(icon: Icons.access_time_outlined,
                      label: 'Time Slot', value: widget.slot),
                  const Divider(),
                  Consumer(builder: (_, ref, __) {
                    final user = ref.watch(currentAppUserProvider).valueOrNull;
                    return _ConfirmRow(icon: Icons.person_outline,
                        label: 'Name', value: user?.name ?? '');
                  }),
                ],
              ),
            ).animate().fadeIn().scale(),
            const Spacer(),
            PrimaryButton(
              label: 'Confirm Booking',
              fullWidth: true,
              isLoading: _isLoading,
              icon: Icons.check_circle_outline,
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Go Back'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.slate, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 14, color: AppColors.ink)),
        ],
      ),
    );
  }
}

// ─── Booking Success Screen ───────────────────────────────────────────────────
class BookingSuccessScreen extends StatelessWidget {
  final Booking booking;
  const BookingSuccessScreen({super.key, required this.booking});

  String get _shareText =>
      '🏟 GreenField Club — Booking Confirmed!\n\n'
      '${booking.groundIcon} ${booking.groundName}\n'
      '📅 ${DateFormat('EEEE, d MMMM yyyy').format(booking.date)}\n'
      '⏰ ${booking.slot}\n'
      '👤 ${booking.userName}\n\n'
      'Booked via GreenField Club App ✅';

  void _shareWhatsApp() async {
    final url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_shareText)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _shareGeneral() {
    Share.share(_shareText, subject: 'My Slot Booking at GreenField Club');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.forest, AppColors.green],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 60),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1,1), end: const Offset(1.05,1.05),
                    duration: 1200.ms, curve: Curves.easeInOut),

                const SizedBox(height: 20),
                const Text('Booking Confirmed! 🎉',
                    style: TextStyle(color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('See you on the field, ${booking.userName.split(' ').first}!',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),

                // Booking Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
                        blurRadius: 30)],
                  ),
                  child: Column(
                    children: [
                      Text(booking.groundIcon, style: const TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text(booking.groundName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      const SizedBox(height: 16),
                      _BookingDetailRow(
                        icon: Icons.calendar_today_outlined,
                        value: DateFormat('EEEE, d MMMM yyyy').format(booking.date),
                      ),
                      const Divider(height: 20),
                      _BookingDetailRow(
                        icon: Icons.access_time_outlined,
                        value: booking.slot,
                      ),
                      const Divider(height: 20),
                      _BookingDetailRow(
                        icon: Icons.person_outline,
                        value: booking.userName,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 24),

                // Share Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareWhatsApp,
                        icon: const Text('📲', style: TextStyle(fontSize: 16)),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareGeneral,
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Text('← Back to Home',
                      style: TextStyle(color: Colors.white.withOpacity(0.8))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingDetailRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _BookingDetailRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.slate),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 14, color: AppColors.ink)),
        ),
      ],
    );
  }
}
