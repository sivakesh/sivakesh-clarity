import 'package:flutter/material.dart';

class AssessmentSuggestionCard extends StatelessWidget {
  final String assessmentType;
  final VoidCallback onTakeAssessment;

  const AssessmentSuggestionCard({
    super.key,
    required this.assessmentType,
    required this.onTakeAssessment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2CFFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Would you like to take a quick $assessmentType assessment?',
              style: const TextStyle(color: Color(0xFFE3E6ED), height: 1.35),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onTakeAssessment,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE9EBEF),
              foregroundColor: const Color(0xFF17191D),
            ),
            child: const Text('Take Assessment'),
          ),
        ],
      ),
    );
  }
}
