import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isMobile) {
      return _buildMobileAdmin(context);
    }
    return _buildWebAdmin(context);
  }

  Widget _buildMobileAdmin(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildWebAdmin(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 88,
      color: const Color(0xFF121212),
      child: SafeArea(
        child: NavigationRail(
          backgroundColor: const Color(0xFF121212),
          selectedIndex: _currentIndex,
          onDestinationSelected: (value) => setState(() => _currentIndex = value),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard, size: 24),
              selectedIcon: Icon(Icons.dashboard, size: 24, color: Colors.white),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people, size: 24),
              selectedIcon: Icon(Icons.people, size: 24, color: Colors.white),
              label: Text('Users'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.analytics, size: 24),
              selectedIcon: Icon(Icons.analytics, size: 24, color: Colors.white),
              label: Text('Analytics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x22FFFFFF)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Admin Panel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return const AdminDashboard();
      case 1:
        return const AdminUsers();
      case 2:
        return const AdminAnalytics();
      default:
        return const AdminDashboard();
    }
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference<Map<String, dynamic>> _checkinsRef =
      FirebaseFirestore.instance.collection('momentCheckins');
  static const Map<String, int> _moodScores = {
    'Calm': 4,
    'Okay': 3,
    'Stressed': 2,
    'Low': 1,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _usersRef.snapshots(),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.hasError) {
          return const _AdminMessageCard(message: 'Unable to load dashboard.');
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Fetch recent check-ins once as stream and process in memory.
          // TODO: add pagination/window controls if admin data grows significantly.
          stream: _checkinsRef
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, checkinsSnapshot) {
            if (checkinsSnapshot.hasError) {
              return const _AdminMessageCard(message: 'Unable to load dashboard.');
            }
            if (usersSnapshot.connectionState == ConnectionState.waiting ||
                checkinsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = usersSnapshot.data?.docs ?? [];
            final checkins = checkinsSnapshot.data?.docs ?? [];
            if (checkins.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: _AdminMessageCard(message: 'No check-ins yet'),
              );
            }

            final todayStart = DateTime(now.year, now.month, now.day);
            int todayCount = 0;
            int moodScoreSum = 0;
            int moodScoreCount = 0;
            final moodCounts = <String, int>{'Calm': 0, 'Okay': 0, 'Stressed': 0, 'Low': 0};
            final dailyCounts = <String, int>{};
            final last7DateKeys = List.generate(7, (i) {
              final d = now.subtract(Duration(days: 6 - i));
              return _dateKey(d);
            });
            for (final k in last7DateKeys) {
              dailyCounts[k] = 0;
            }

            for (final doc in checkins) {
              final data = doc.data();
              final mood = (data['mood'] as String?) ?? '';
              final ts = data['createdAt'];
              if (ts is! Timestamp) continue;
              final dt = ts.toDate();
              if (!dt.isBefore(todayStart)) todayCount++;
              final dateKey = _dateKey(dt);
              if (dailyCounts.containsKey(dateKey)) {
                dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
              }
              if (moodCounts.containsKey(mood)) {
                moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
              }
              final score = _moodScores[mood];
              if (score != null) {
                moodScoreSum += score;
                moodScoreCount++;
              }
            }

            final averageMood = moodScoreCount == 0 ? 0.0 : moodScoreSum / moodScoreCount;
            final averageLabel = _averageLabel(averageMood);
            final isMobile = MediaQuery.of(context).size.width < 768;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: isMobile ? 2 : 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isMobile ? 1.3 : 1.8,
                    children: [
                      _summaryCard('Total Users', '${users.length}', onTap: _openCheckins),
                      _summaryCard('Total Check-ins', '${checkins.length}', onTap: _openCheckins),
                      _summaryCard("Today's Check-ins", '$todayCount', onTap: _openCheckins),
                      _summaryCard('Average Mood', '${averageMood.toStringAsFixed(1)} • $averageLabel',
                          onTap: _openCheckins),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Daily Trend (Last 7 Days)',
                    onTap: _openCheckins,
                    child: Column(
                      children: last7DateKeys.map((key) {
                        final count = dailyCounts[key] ?? 0;
                        final maxCount = dailyCounts.values.fold<int>(1, (p, e) => e > p ? e : p);
                        final widthFactor = count == 0 ? 0.04 : (count / maxCount);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 56,
                                child: Text(
                                  key.substring(5),
                                  style: const TextStyle(color: Color(0xFFAEB4BF), fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: widthFactor,
                                    minHeight: 10,
                                    backgroundColor: const Color(0x1FFFFFFF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7EA2FF)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('$count', style: const TextStyle(color: Color(0xFFD8DCE5))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Mood Distribution',
                    onTap: _openCheckins,
                    child: Column(
                      children: moodCounts.entries.map((entry) {
                        final total = moodCounts.values.fold<int>(0, (p, e) => p + e);
                        final ratio = total == 0 ? 0.0 : entry.value / total;
                        return InkWell(
                          onTap: _openCheckins,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(entry.key, style: const TextStyle(color: Color(0xFFDDE2EC))),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 10,
                                      backgroundColor: const Color(0x1FFFFFFF),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(Color(0xFFA8B8FF)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${entry.value}',
                                    style: const TextStyle(color: Color(0xFFD8DCE5))),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF15181D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x28FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF9EA6B4), fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF15181D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x28FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _averageLabel(double avg) {
    if (avg >= 3.5) return 'Calm';
    if (avg >= 2.5) return 'Okay';
    if (avg >= 1.5) return 'Stressed';
    return 'Low';
  }

  void _openCheckins() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminCheckinsScreen()),
    );
  }
}

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Users',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openUserDialog(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add User'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _AdminMessageCard(
                    message: 'Unable to load users right now.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _AdminMessageCard(message: 'No users found.');
                }

                if (isMobile) {
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildUserCard(context, docs[index]);
                    },
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF15181D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x28FFFFFF)),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: docs.map((doc) => _buildUserRow(context, doc)).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim();
    final phone = (data['phone'] as String?)?.trim();
    final role = (data['role'] as String?)?.trim().isNotEmpty == true
        ? (data['role'] as String).trim()
        : 'user';
    final status = (data['status'] as String?)?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x28FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name == null || name.isEmpty ? 'Unnamed User' : name),
          const SizedBox(height: 8),
          Text(
            'Phone: ${phone == null || phone.isEmpty ? '-' : phone}',
            style: const TextStyle(color: Color(0xFFB3B8C3)),
          ),
          const SizedBox(height: 4),
          Text('Role: $role', style: const TextStyle(color: Color(0xFFB3B8C3))),
          const SizedBox(height: 4),
          Text(
            'Status: ${status == null || status.isEmpty ? '-' : status}',
            style: const TextStyle(color: Color(0xFFB3B8C3)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: () => _openUserDialog(context, doc: doc),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, doc),
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildUserRow(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim();
    final phone = (data['phone'] as String?)?.trim();
    final role = (data['role'] as String?)?.trim().isNotEmpty == true
        ? (data['role'] as String).trim()
        : 'user';
    final status = (data['status'] as String?)?.trim();

    return DataRow(
      cells: [
        DataCell(Text(name == null || name.isEmpty ? 'Unnamed User' : name)),
        DataCell(Text(phone == null || phone.isEmpty ? '-' : phone)),
        DataCell(Text(role)),
        DataCell(Text(status == null || status.isEmpty ? '-' : status)),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () => _openUserDialog(context, doc: doc),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, doc),
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openUserDialog(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final isEditing = doc != null;
    final data = doc?.data() ?? <String, dynamic>{};

    final nameController = TextEditingController(text: (data['name'] as String?) ?? '');
    final phoneController = TextEditingController(text: (data['phone'] as String?) ?? '');
    final emailController = TextEditingController(text: (data['email'] as String?) ?? '');
    final notesController = TextEditingController(text: (data['notes'] as String?) ?? '');

    String selectedRole = ((data['role'] as String?) ?? 'user').trim().isEmpty
        ? 'user'
        : (data['role'] as String?) ?? 'user';
    String? selectedStatus = (data['status'] as String?)?.trim().isEmpty == true
        ? null
        : (data['status'] as String?);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF15181D),
              title: Text(isEditing ? 'Edit User' : 'Add User'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        enabled: !isEditing,
                        decoration: const InputDecoration(labelText: 'Phone *'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('user')),
                          DropdownMenuItem(value: 'admin', child: Text('admin')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedRole = value);
                        },
                        decoration: const InputDecoration(labelText: 'Role'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email (optional)'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('active')),
                          DropdownMenuItem(value: 'inactive', child: Text('inactive')),
                        ],
                        onChanged: (value) {
                          setLocalState(() => selectedStatus = value);
                        },
                        decoration: const InputDecoration(labelText: 'Status (optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    if (name.isEmpty || (!isEditing && phone.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name and phone are required')),
                      );
                      return;
                    }

                    final payload = <String, dynamic>{
                      'name': name,
                      'role': selectedRole,
                    };

                    final email = emailController.text.trim();
                    if (email.isNotEmpty) payload['email'] = email;
                    final notes = notesController.text.trim();
                    if (notes.isNotEmpty) payload['notes'] = notes;
                    if (selectedStatus != null && selectedStatus!.isNotEmpty) {
                      payload['status'] = selectedStatus;
                    }

                    try {
                      if (isEditing) {
                        await _usersRef.doc(doc.id).update(payload);
                      } else {
                        final newDoc = _usersRef.doc();
                        await newDoc.set({
                          'id': newDoc.id,
                          'name': name,
                          'phone': phone,
                          'role': selectedRole,
                          'createdAt': FieldValue.serverTimestamp(),
                          if (payload.containsKey('email')) 'email': payload['email'],
                          if (payload.containsKey('status')) 'status': payload['status'],
                          if (payload.containsKey('notes')) 'notes': payload['notes'],
                        });
                      }
                      if (context.mounted) Navigator.pop(dialogContext);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Operation failed. Please try again.')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF15181D),
          title: const Text('Delete User'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    try {
      await _usersRef.doc(doc.id).delete();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed. Please try again.')),
      );
    }
  }
}

class AdminAnalytics extends StatelessWidget {
  const AdminAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminPlaceholder(title: 'Analytics');
  }
}

class AdminCheckinsScreen extends StatefulWidget {
  const AdminCheckinsScreen({super.key});

  @override
  State<AdminCheckinsScreen> createState() => _AdminCheckinsScreenState();
}

class _AdminCheckinsScreenState extends State<AdminCheckinsScreen> {
  final CollectionReference<Map<String, dynamic>> _checkinsRef =
      FirebaseFirestore.instance.collection('momentCheckins');
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  DateTimeRange? _range;
  String? _selectedMood;
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-ins')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _usersRef.snapshots(),
        builder: (context, usersSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _checkinsRef
                .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, checkinsSnapshot) {
              if (usersSnapshot.hasError || checkinsSnapshot.hasError) {
                return const Center(child: Text('Unable to load check-ins right now.'));
              }
              if (usersSnapshot.connectionState == ConnectionState.waiting ||
                  checkinsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = usersSnapshot.data?.docs ?? [];
              final userNameById = <String, String>{
                for (final u in users)
                  u.id: ((u.data()['name'] as String?)?.trim().isNotEmpty == true)
                      ? (u.data()['name'] as String).trim()
                      : 'Unnamed User',
              };

              final raw = checkinsSnapshot.data?.docs ?? [];
              final filtered = raw.where((doc) {
                final data = doc.data();
                final mood = (data['mood'] as String?) ?? '';
                final uid = (data['userId'] as String?) ?? '';
                final ts = data['createdAt'];
                if (ts is! Timestamp) return false;
                final dt = ts.toDate();

                if (_selectedMood != null && _selectedMood != mood) return false;
                if (_selectedUserId != null && _selectedUserId != uid) return false;
                if (_range != null) {
                  final start = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
                  final end = DateTime(
                    _range!.end.year,
                    _range!.end.month,
                    _range!.end.day,
                    23,
                    59,
                    59,
                  );
                  if (dt.isBefore(start) || dt.isAfter(end)) return false;
                }
                return true;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _range == null
                                ? 'Date Range'
                                : '${_shortDate(_range!.start)} - ${_shortDate(_range!.end)}',
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedMood,
                          hint: const Text('Mood'),
                          items: const [
                            DropdownMenuItem(value: 'Calm', child: Text('Calm')),
                            DropdownMenuItem(value: 'Okay', child: Text('Okay')),
                            DropdownMenuItem(value: 'Stressed', child: Text('Stressed')),
                            DropdownMenuItem(value: 'Low', child: Text('Low')),
                          ],
                          onChanged: (value) => setState(() => _selectedMood = value),
                        ),
                        DropdownButton<String>(
                          value: _selectedUserId,
                          hint: const Text('User'),
                          items: users
                              .map(
                                (u) => DropdownMenuItem<String>(
                                  value: u.id,
                                  child: Text(
                                    ((u.data()['name'] as String?)?.trim().isNotEmpty == true)
                                        ? (u.data()['name'] as String).trim()
                                        : 'Unnamed User',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _selectedUserId = value),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _range = null;
                              _selectedMood = null;
                              _selectedUserId = null;
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filtered.isEmpty
                          ? const _AdminMessageCard(message: 'No check-ins found for selected filters.')
                          : isMobile
                              ? ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final data = filtered[index].data();
                                    final uid = (data['userId'] as String?) ?? '';
                                    final mood = (data['mood'] as String?) ?? '-';
                                    final ts = data['createdAt'] as Timestamp?;
                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF15181D),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0x28FFFFFF)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userNameById[uid] ?? 'Unknown User'),
                                          const SizedBox(height: 6),
                                          Text('Mood: $mood',
                                              style: const TextStyle(color: Color(0xFFB3B8C3))),
                                          const SizedBox(height: 4),
                                          Text('Date: ${_fullDate(ts?.toDate())}',
                                              style: const TextStyle(color: Color(0xFFB3B8C3))),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF15181D),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0x28FFFFFF)),
                                  ),
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('User')),
                                        DataColumn(label: Text('Phone')),
                                        DataColumn(label: Text('Mood')),
                                        DataColumn(label: Text('Date')),
                                      ],
                                      rows: filtered.map((doc) {
                                        final data = doc.data();
                                        final uid = (data['userId'] as String?) ?? '';
                                        final mood = (data['mood'] as String?) ?? '-';
                                        final ts = data['createdAt'] as Timestamp?;
                                        final userData = usersSnapshot.data?.docs
                                            .where((u) => u.id == uid)
                                            .map((u) => u.data())
                                            .cast<Map<String, dynamic>?>()
                                            .firstOrNull;
                                        final rawPhone = (userData?['phone'] as String?)?.trim();
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(userNameById[uid] ?? 'User')),
                                            DataCell(Text(
                                              rawPhone == null || rawPhone.isEmpty
                                                  ? '-'
                                                  : maskPhone(rawPhone),
                                            )),
                                            DataCell(Text(mood)),
                                            DataCell(Text(_fullDate(ts?.toDate()))),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  String _shortDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _fullDate(DateTime? date) {
    if (date == null) return '--';
    return '${_shortDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String maskPhone(String phone) {
    if (phone.length < 6) return phone;
    return phone.replaceRange(3, phone.length - 2, '*' * (phone.length - 5));
  }
}

class _AdminPlaceholder extends StatelessWidget {
  final String title;

  const _AdminPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title (Placeholder)',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AdminMessageCard extends StatelessWidget {
  final String message;

  const _AdminMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF15181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x28FFFFFF)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFC4C8D1)),
      ),
    );
  }
}
