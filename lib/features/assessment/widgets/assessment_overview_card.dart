import 'package:flutter/material.dart';

class AssessmentOverviewCard extends StatelessWidget {
  const AssessmentOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Check',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            '7 short prompts to help track mood, energy, and focus over time.',
            style: TextStyle(color: Color(0xFFAAAAAA), height: 1.4),
          ),
          SizedBox(height: 18),
          LinearProgressIndicator(
            value: 0.0,
            minHeight: 8,
            backgroundColor: Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}
