import 'package:flutter/foundation.dart';

class ChatEntryContext {
  final String? mood;
  final String? source;

  const ChatEntryContext({this.mood, this.source});
}

class ChatEntryContextBus {
  static final ValueNotifier<ChatEntryContext?> notifier = ValueNotifier(null);

  static void set({String? mood, String? source}) {
    notifier.value = ChatEntryContext(mood: mood, source: source);
  }
}
