import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../booking/book_ground_screen.dart';
import '../feedback/feedback_screen.dart';
import '../tournament/tournament_screen.dart';
import '../admin/admin_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final canTournament = user?.canAccessTournaments ?? false;

    final pages = [
      const HomeScreen(),
      const BookGroundScreen(),
      if (canTournament) const TournamentScreen(),
      const FeedbackScreen(),
      if (isAdmin) const AdminScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.sports_outlined),
          activeIcon: Icon(Icons.sports_rounded), label: 'Book'),
      if (canTournament)
        const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events_rounded), label: 'Tournaments'),
      const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Feedback'),
      if (isAdmin)
        const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded), label: 'Admin'),
    ];

    // Clamp index when admin status changes
    final clampedIndex = _index.clamp(0, pages.length - 1);

    final adminPageIndex = isAdmin ? pages.length - 1 : -1;
    final adminTabIndex = ref.watch(adminTabIndexProvider);
    final onAdminNonOverview =
        clampedIndex == adminPageIndex && adminTabIndex != 0;

    return PopScope(
      canPop: false, // We handle ALL back navigation manually
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (onAdminNonOverview) {
          // On admin non-overview tab → go to Overview
          ref.read(adminTabIndexProvider.notifier).state = 0;
        } else if (clampedIndex != 0) {
          // On any non-home tab → go to Home
          setState(() => _index = 0);
        } else if (!kIsWeb) {
          // On Home tab on Android → exit app
          await SystemNavigator.pop();
        }
        // On Home tab on Web → do nothing (can't close browser tab)
      },
      child: Scaffold(
        body: IndexedStack(
          index: clampedIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: clampedIndex,
          onTap: (i) => setState(() => _index = i),
          items: navItems,
        ),
      ),
    );
  }
}
