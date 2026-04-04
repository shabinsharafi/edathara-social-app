import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../booking/book_ground_screen.dart';
import '../feedback/feedback_screen.dart';
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

    final pages = [
      const HomeScreen(),
      const BookGroundScreen(),
      const FeedbackScreen(),
      if (isAdmin) const AdminScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.sports_outlined),
          activeIcon: Icon(Icons.sports_rounded), label: 'Book'),
      const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Feedback'),
      if (isAdmin)
        const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded), label: 'Admin'),
    ];

    // Clamp index when admin status changes
    final clampedIndex = _index.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: clampedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: clampedIndex,
        onTap: (i) => setState(() => _index = i),
        items: navItems,
      ),
    );
  }
}
