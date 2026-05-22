import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onStartJourney;

  const ActionButtons({super.key, required this.onStartJourney});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 520;

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: useRow ? 240 : double.infinity,
            child: FilledButton(
              onPressed: onStartJourney,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Start Journey'),
            ),
          ),
        );
      },
    );
  }
}
