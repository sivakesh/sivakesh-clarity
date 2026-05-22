import 'package:flutter/material.dart';

import '../../core/auth/auth_factory.dart';
import '../assessment/screens/assessment_screen.dart';
import '../chat/screens/chat_screen.dart';
import '../chat/data/chat_entry_context.dart';
import '../home/screens/home_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../auth/screens/login_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);
  final _authService = AuthFactory.create();
  bool _isLoggingOut = false;

  late final List<_NavDestination> _destinations;

  @override
  void initState() {
    super.initState();
      _destinations = [
        _NavDestination(
          label: 'Home',
          icon: Icons.home_rounded,
          screen: HomeScreen(
            onStartJourney: () => _currentIndex.value = 2,
            onReflectMore: () {
              ChatEntryContextBus.set(source: 'reflect_button');
              _currentIndex.value = 1;
            },
            onTakeAssessment: () => _currentIndex.value = 2,
            onTalkItOut: (_) {
              _currentIndex.value = 1;
            },
          ),
        ),
      const _NavDestination(
        label: 'Chat',
        icon: Icons.chat_bubble_rounded,
        screen: ChatScreen(),
      ),
      const _NavDestination(
        label: 'Assess',
        icon: Icons.checklist_rounded,
        screen: AssessmentScreen(),
      ),
      const _NavDestination(
        label: 'Profile',
        icon: Icons.person_rounded,
        screen: ProfileScreen(),
      ),
    ];
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentIndex,
      builder: (context, index, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            if (isWide) {
              return Scaffold(
                body: Row(
                  children: [
                    Container(
                      width: 88,
                      color: const Color(0xFF121212),
                      child: Column(
                        children: [
                          Expanded(
                            child: NavigationRail(
                              backgroundColor: const Color(0xFF121212),
                              selectedIndex: index,
                              onDestinationSelected: (value) =>
                                  _currentIndex.value = value,
                              labelType: NavigationRailLabelType.all,
                              destinations: _destinations
                                  .map(
                                    (item) => NavigationRailDestination(
                                      icon: Icon(item.icon),
                                      selectedIcon: Icon(
                                        item.icon,
                                        color: Colors.white,
                                      ),
                                      label: Text(item.label),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                            child: Tooltip(
                              message: 'Logout',
                              child: InkWell(
                                onTap: _isLoggingOut ? null : () => _handleLogout(context),
                                borderRadius: BorderRadius.circular(12),
                                hoverColor: const Color(0x22FF8C8C),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0x33FF9A9A)),
                                  ),
                                  child: Column(
                                    children: [
                                      _isLoggingOut
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFE8B0B0),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.logout_rounded,
                                              color: Color(0xFFE8B0B0),
                                              size: 18,
                                            ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Color(0xFFE8B0B0),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFF252525)),
                    Expanded(child: _destinations[index].screen),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFF121212),
                elevation: 0,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed: _isLoggingOut ? null : () => _handleLogout(context),
                      icon: _isLoggingOut
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE8B0B0),
                      ),
                    ),
                  ),
                ],
              ),
              body: _destinations[index].screen,
              bottomNavigationBar: NavigationBar(
                height: 74,
                backgroundColor: const Color(0xFF121212),
                selectedIndex: index,
                onDestinationSelected: (value) => _currentIndex.value = value,
                destinations: _destinations
                    .map(
                      (item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    setState(() {
      _isLoggingOut = true;
    });
    try {
      await _authService.logout();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final Widget screen;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.screen,
  });
}
