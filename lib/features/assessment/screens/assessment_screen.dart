import 'package:flutter/material.dart';

import '../../common/widgets/app_header.dart';
import '../../common/widgets/page_shell.dart';
import '../widgets/assessment_overview_card.dart';

class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: PageShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Text(
                      'Assessment',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'A quick reflection to understand your current emotional baseline.',
                      style: TextStyle(color: Color(0xFFAFAFAF)),
                    ),
                    SizedBox(height: 24),
                    AssessmentOverviewCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
