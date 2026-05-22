import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_factory.dart';
import '../../../models/user_model.dart';
import '../../assessment/screens/assessment_screen.dart';
import '../../common/widgets/app_header.dart';
import '../../common/widgets/page_shell.dart';
import '../data/chat_entry_context.dart';
import '../models/chat_message.dart';
import '../services/chat_flow_service.dart';
import '../services/chat_service.dart';
import '../widgets/assessment_suggestion_card.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMood;
  final String? source;

  const ChatScreen({super.key, this.initialMood, this.source});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final ChatFlowService _flowService = ChatFlowService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _user;
  String? _sessionId;
  String? _activeMood;
  String? _activeSource;
  int _exchangeCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    ChatEntryContextBus.notifier.addListener(_consumeEntryContext);
  }

  Future<void> _bootstrap() async {
    try {
      final user = await AuthFactory.create().getCurrentUser();
      if (!mounted || user == null) return;

      _user = user;
      _activeMood = widget.initialMood;
      _activeSource = widget.source;

      final session = await _chatService.getOrCreateLatestSession(
        userId: user.id,
        mood: _activeMood,
        source: _activeSource,
      );

      _sessionId = session.id;

      final snapshot = await FirebaseFirestore.instance
          .collection('chatSessions')
          .doc(session.id)
          .collection('messages')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        final seed = _flowService.initialAssistantMessages(
          userId: user.id,
          mood: _activeMood,
          source: _activeSource,
        );

        for (final message in seed) {
          await _chatService.addMessage(
            sessionId: session.id,
            userId: user.id,
            message: message,
          );
        }
      }
    } catch (e) {
      debugPrint('Chat bootstrap error: $e');
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _consumeEntryContext() async {
    final entry = ChatEntryContextBus.notifier.value;
    final user = _user;
    final sessionId = _sessionId;
    if (entry == null || user == null || sessionId == null) return;

    _activeMood = entry.mood ?? _activeMood;
    _activeSource = entry.source ?? _activeSource;

    final seed = _flowService.initialAssistantMessages(
      userId: user.id,
      mood: _activeMood,
      source: _activeSource,
    );
    await _chatService.addMessage(
      sessionId: sessionId,
      userId: user.id,
      message: seed.first,
    );

    ChatEntryContextBus.notifier.value = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ChatEntryContextBus.notifier.removeListener(_consumeEntryContext);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final user = _user;
    final sessionId = _sessionId;
    final text = _controller.text.trim();
    if (user == null || sessionId == null || text.isEmpty) return;

    _controller.clear();

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      role: 'user',
      text: text,
      createdAt: Timestamp.now(),
      moodContext: _activeMood,
      source: _activeSource,
    );
    await _chatService.addMessage(
      sessionId: sessionId,
      userId: user.id,
      message: userMessage,
    );

    _exchangeCount += 1;
    final reply = _flowService.respond(
      userId: user.id,
      userText: text,
      mood: _activeMood,
      exchangeCount: _exchangeCount,
    );
    await _chatService.addMessage(
      sessionId: sessionId,
      userId: user.id,
      message: reply,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: PageShell(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF16181D), Color(0xFF111216)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x28FFFFFF)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Expanded(child: _buildMessages()),
                    const SizedBox(height: 12),
                    _buildInput(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    final user = _user;
    final sessionId = _sessionId;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (user == null || sessionId == null) {
      return const Center(child: Text('Unable to load chat'));
    }

    return StreamBuilder<List<ChatMessage>>(
      key: const ValueKey('chat_messages_stream'),
      stream: _chatService.messagesStream(sessionId: sessionId, userId: user.id),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <ChatMessage>[];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'Start with a gentle message when you are ready.',
              style: TextStyle(color: Color(0xFF9CA2AE)),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final m = messages[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChatBubble(role: m.role, text: m.text),
                if (m.assessmentSuggestion != null)
                  AssessmentSuggestionCard(
                    assessmentType: m.assessmentSuggestion!,
                    onTakeAssessment: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AssessmentScreen(),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              style: const TextStyle(color: Color(0xFFE7EAF0)),
              decoration: const InputDecoration(
                hintText: 'Share what is on your mind...',
                hintStyle: TextStyle(color: Color(0xFF7A7A7A)),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _send,
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
