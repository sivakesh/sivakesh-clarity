import 'package:flutter/material.dart';

import '../../../core/auth/auth_factory.dart';
import '../../../models/user_model.dart';
import '../../chat/data/chat_entry_context.dart';
import '../../chat/services/chat_debug_service.dart';
import '../../common/widgets/app_header.dart';
import '../../common/widgets/page_shell.dart';
import '../widgets/action_buttons.dart';
import '../widgets/home_header.dart';
import '../widgets/mood_check_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onStartJourney;
  final VoidCallback onReflectMore;
  final VoidCallback onTakeAssessment;
  final ValueChanged<String> onTalkItOut;

  const HomeScreen({
    super.key,
    required this.onStartJourney,
    required this.onReflectMore,
    required this.onTakeAssessment,
    required this.onTalkItOut,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<UserModel?> _currentUserFuture;
  final ChatDebugService _chatDebugService = ChatDebugService();
  bool _isSettingUpChatDb = false;
  String? _selectedMoodForAction;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = AuthFactory.create().getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
                child: PageShell(
                child: FutureBuilder<UserModel?>(
                  future: _currentUserFuture,
                  builder: (context, snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const HomeHeader(),
                        const SizedBox(height: 24),
                        MoodCheckCard(
                          userId: snapshot.data?.id,
                          onReflectMore: widget.onReflectMore,
                          onTakeAssessment: widget.onTakeAssessment,
                          onMoodSelected: (mood) {
                            if (mood == null || mood.isEmpty) return;
                            setState(() {
                              _selectedMoodForAction = mood;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        ActionButtons(
                          onStartJourney: widget.onStartJourney,
                        ),
                        if (AuthFactory.isDev) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _isSettingUpChatDb
                                ? null
                                : () => _setupChatDb(snapshot.data?.id),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x33FFFFFF)),
                              foregroundColor: const Color(0xFFD7DBE4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSettingUpChatDb
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Setup Chat DB'),
                          ),
                        ],
                        if (_selectedMoodForAction != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171A20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0x2DFFFFFF)),
                            ),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    final mood = _selectedMoodForAction;
                                    if (mood == null) return;
                                    ChatEntryContextBus.notifier.value =
                                        ChatEntryContext(
                                          mood: mood,
                                          source: 'home_mood_check',
                                        );
                                    widget.onTalkItOut(mood);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0x39FFFFFF),
                                    ),
                                    foregroundColor: const Color(0xFFE2E6EF),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Talk it out'),
                                ),
                                FilledButton(
                                  onPressed: widget.onStartJourney,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE9EBEF),
                                    foregroundColor: const Color(0xFF17191D),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Take assessment'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setupChatDb(String? userId) async {
    FocusScope.of(context).unfocus();
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to setup: missing user session')),
      );
      return;
    }

    setState(() {
      _isSettingUpChatDb = true;
    });

    try {
      final sessionId = await _chatDebugService.setupSampleChat(userId: userId);
      print('Setup Chat DB success. sessionId=$sessionId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat DB setup complete')),
      );
    } catch (e) {
      print('Setup Chat DB failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Setup failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSettingUpChatDb = false;
        });
      }
    }
  }
}
