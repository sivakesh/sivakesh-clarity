import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

class ChatFlowService {
  List<ChatMessage> initialAssistantMessages({
    required String userId,
    String? mood,
    String? source,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch.toString();

    String primary;
    String followUp;
    String? suggestion;

    switch (mood) {
      case 'Calm':
        primary = 'Glad you are feeling calm today.';
        followUp = 'Would you like to reflect on what is helping you feel steady?';
        suggestion = 'MIND-7';
        break;
      case 'Okay':
        primary = 'Would you like to understand your emotional patterns better?';
        followUp = 'If you want, we can start with a gentle reflection together.';
        suggestion = 'MIND-7';
        break;
      case 'Stressed':
        primary = 'I hear that things feel stressful right now. Let us pause for a breath first.';
        followUp = 'What feels heaviest right now: workload, emotions, or uncertainty?';
        suggestion = 'MIND-7';
        break;
      case 'Low':
        primary = 'Thank you for sharing this. It is okay to move gently today.';
        followUp = 'How are your energy, sleep, and motivation lately?';
        suggestion = 'MIND-9';
        break;
      default:
        primary = 'I am here with you. We can reflect at your pace.';
        followUp = 'How has your day felt emotionally so far?';
    }

    return [
      ChatMessage(
        id: 'sys_$now',
        userId: userId,
        role: 'assistant',
        text: primary,
        createdAt: Timestamp.now(),
        moodContext: mood,
        source: source,
      ),
      ChatMessage(
        id: 'sys_${now}b',
        userId: userId,
        role: 'assistant',
        text: followUp,
        createdAt: Timestamp.now(),
        moodContext: mood,
        source: source,
        assessmentSuggestion: suggestion,
      ),
    ];
  }

  ChatMessage respond({
    required String userId,
    required String userText,
    String? mood,
    int exchangeCount = 0,
  }) {
    final text = userText.toLowerCase();
    String reply = 'Thank you for sharing that. Tell me a little more if you want.';
    String? suggestion;

    if (text.contains('sleep') || text.contains('tired')) {
      reply = 'Sleep can deeply shape how we feel. How rested have you felt this week?';
    } else if (text.contains('work') || text.contains('study')) {
      reply = 'That sounds like a lot to carry. What part feels most draining right now?';
    } else if (text.contains('anx') || text.contains('stress')) {
      reply = 'That sounds intense. A short pause and naming one manageable next step can help.';
    } else if (text.contains('motivation')) {
      reply = 'Motivation can fluctuate. What is one small action that still feels possible today?';
    }

    if ((mood == 'Stressed' || mood == 'Okay') && exchangeCount >= 2) {
      suggestion = 'MIND-7';
    }
    if (mood == 'Low' && exchangeCount >= 2) {
      suggestion = 'MIND-9';
    }

    return ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      role: 'assistant',
      text: reply,
      createdAt: Timestamp.now(),
      moodContext: mood,
      assessmentSuggestion: suggestion,
    );
  }
}
