import 'package:flutter/material.dart';

import '../../core/auth/auth_factory.dart';
import '../../models/user_model.dart';
import '../admin/admin_shell.dart';
import '../assessment/screens/assessment_screen.dart';
import '../chat/screens/chat_screen.dart';
import '../chat/data/chat_entry_context.dart';
import '../home/screens/home_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../auth/screens/login_screen.dart';

class MainNavigation extends StatefulWidget {
  final UserModel? user;

  const MainNavigation({super.key, this.user});

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
              const double sidebarWidth = 72;
              final bool isCollapsed = sidebarWidth < 100;
              return Scaffold(
                body: Row(
                  children: [
                    Container(
                      width: sidebarWidth,
                      color: const Color(0xFF121212),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: isCollapsed
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Tooltip(
                                            message: 'Logout',
                                            child: InkWell(
                                              onTap: _isLoggingOut ? null : () => _handleLogout(context),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                height: 48,
                                                alignment: Alignment.center,
                                                child: _isLoggingOut
                                                    ? const SizedBox(
                                                        height: 16,
                                                        width: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white70,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.logout,
                                                        color: Colors.white70,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : OutlinedButton.icon(
                                          onPressed: _isLoggingOut ? null : () => _handleLogout(context),
                                          icon: _isLoggingOut
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white70,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.logout,
                                                  size: 18,
                                                  color: Colors.white70,
                                                ),
                                          label: const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Logout',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            alignment: Alignment.centerLeft,
                                            side: const BorderSide(color: Colors.white24),
                                            backgroundColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ).copyWith(
                                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return Colors.white12;
                                              }
                                              return Colors.transparent;
                                            }),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                if (_isAdmin)
                                  SizedBox(
                                    width: double.infinity,
                                    child: isCollapsed
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Tooltip(
                                              message: 'Admin',
                                              child: InkWell(
                                                onTap: () => _openAdmin(context),
                                                borderRadius: BorderRadius.circular(12),
                                                child: const SizedBox(
                                                  height: 48,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.admin_panel_settings,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : OutlinedButton.icon(
                                            onPressed: () => _openAdmin(context),
                                            icon: const Icon(
                                              Icons.admin_panel_settings,
                                              size: 18,
                                              color: Color(0xFFB7CCFF),
                                            ),
                                            label: const Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Admin',
                                                style: TextStyle(
                                                  color: Color(0xFFB7CCFF),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              alignment: Alignment.centerLeft,
                                              side: const BorderSide(color: Color(0x337FA8FF)),
                                              backgroundColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ).copyWith(
                                              backgroundColor: WidgetStateProperty.resolveWith((states) {
                                                if (states.contains(WidgetState.hovered)) {
                                                  return Colors.white12;
                                                }
                                                return Colors.transparent;
                                              }),
                                            ),
                                          ),
                                  ),
                              ],
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
                  if (_isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'admin') {
                          _openAdmin(context);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 18),
                              SizedBox(width: 8),
                              Text('Admin'),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                          : const Icon(
                              Icons.logout,
                              size: 18,
                              color: Colors.white70,
                            ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.white12;
                          }
                          return Colors.transparent;
                        }),
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

  bool get _isAdmin => widget.user?.role == 'admin';

  void _openAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminShell()),
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
