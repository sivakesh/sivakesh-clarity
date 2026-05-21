import 'package:flutter/material.dart';

import '../../common/widgets/app_header.dart';
import '../../common/widgets/page_shell.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_input_box.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: PageShell(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(child: ChatEmptyState()),
                  SizedBox(height: 12),
                  ChatInputBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
