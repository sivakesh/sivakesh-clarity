import 'package:flutter/material.dart';

class PageShell extends StatelessWidget {
  final Widget child;

  const PageShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: child,
        ),
      ),
    );
  }
}
