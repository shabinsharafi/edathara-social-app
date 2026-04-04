import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class FundraiserScreen extends ConsumerWidget {
  const FundraiserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundAsync = ref.watch(fundraisersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fund Raising 💰')),
      backgroundColor: AppColors.cream,
      body: fundAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          emoji: '⚠️', title: 'Failed to load', subtitle: 'Please try again',
        ),
        data: (funds) => funds.isEmpty
            ? const EmptyState(
                emoji: '💰',
                title: 'No campaigns yet',
                subtitle: 'Admin will post fundraising campaigns here',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: funds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) =>
                    _FundCard(fund: funds[i])
                        .animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.1),
              ),
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  final Fundraiser fund;
  const _FundCard({required this.fund});

  String _fmt(double v) => NumberFormat.compact(locale: 'en_IN').format(v);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fund.imageUrl != null) ...[
            AppNetworkImage(url: fund.imageUrl, height: 160),
            const SizedBox(height: 14),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(fund.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 11, color: AppColors.mint),
                    const SizedBox(width: 4),
                    Text(fund.deadline,
                        style: const TextStyle(fontSize: 11, color: AppColors.mint,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(fund.description,
              style: const TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5)),
          const SizedBox(height: 16),

          // Progress
          FundProgressBar(progress: fund.progressPercent),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(text: TextSpan(
                style: const TextStyle(fontFamily: 'Outfit'),
                children: [
                  TextSpan(text: '₹${_fmt(fund.raisedAmount)} ',
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 16, color: AppColors.mint)),
                  TextSpan(text: 'raised',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                ],
              )),
              Text(
                '${(fund.progressPercent * 100).toStringAsFixed(0)}% of ₹${_fmt(fund.goalAmount)}',
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Contribute Now',
            fullWidth: true,
            icon: Icons.favorite_outline,
            color: AppColors.gold,
            onPressed: () => _showContribute(context),
          ),
        ],
      ),
    );
  }

  void _showContribute(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contribute', style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text('To: ${fund.title}',
                style: const TextStyle(color: AppColors.slate, fontSize: 13)),
            const SizedBox(height: 20),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 16),
            // Payment note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.slate),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment via UPI / bank transfer. Contact admin for details.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Proceed to Pay',
              fullWidth: true,
              icon: Icons.arrow_forward_outlined,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
