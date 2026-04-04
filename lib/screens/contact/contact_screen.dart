import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider).valueOrNull ?? _defaults();

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Contacts 📞')),
      backgroundColor: AppColors.cream,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) =>
            _ContactCard(contact: contacts[i])
                .animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.05),
      ),
    );
  }

  List<QuickContact> _defaults() => [
    QuickContact(id: '1', name: 'Ground Manager', phone: '+91 98765 43210',
        role: 'Bookings & Ground', sortOrder: 0),
    QuickContact(id: '2', name: 'Club Secretary', phone: '+91 91234 56789',
        role: 'Memberships & Admin', sortOrder: 1),
    QuickContact(id: '3', name: 'Emergency', phone: '112',
        role: 'Security & Emergency', sortOrder: 2),
  ];
}

class _ContactCard extends StatelessWidget {
  final QuickContact contact;
  const _ContactCard({required this.contact});

  void _call() async {
    final url = Uri.parse('tel:${contact.phone}');
    if (await canLaunchUrl(url)) launchUrl(url);
  }

  void _whatsapp() async {
    final url = Uri.parse('https://wa.me/${contact.phone.replaceAll(RegExp(r'[^0-9]'), '')}');
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          UserAvatar(name: contact.name, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 15, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(contact.role, style: const TextStyle(fontSize: 12,
                    color: AppColors.slate)),
                const SizedBox(height: 2),
                Text(contact.phone, style: const TextStyle(fontSize: 13,
                    color: AppColors.mint, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            children: [
              _ActionBtn(icon: Icons.phone_outlined, color: AppColors.mint, onTap: _call),
              const SizedBox(height: 8),
              _ActionBtn(icon: Icons.chat_outlined, color: const Color(0xFF25D366),
                  onTap: _whatsapp),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
