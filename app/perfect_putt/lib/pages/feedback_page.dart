import 'package:flutter/material.dart';
import 'session_ready_page.dart';
import 'instructions_page.dart';
import '../widgets/page_layout.dart';
import '../putting_feedback/putting_feedback.dart';
import '../globals/globals.dart';


class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Feedback",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currFeedback.resultsMessage,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Feedback details
          Text(currFeedback.impactMessage),
          Text(currFeedback.followThroughMessage),
          Text(currFeedback.tempoMessage),
          Text(currFeedback.stabilityMessage),
          Text(currFeedback.straightnessMessage),
          Text(currFeedback.directionMessage),

          // Debugging metrics
          Text(currFeedback.dataSummary),

          const Text("Click below to view instructions or swing again."),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SessionReadyPage()),
              );
            },
            child: const Text("Swing Again"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const InstructionsPage()),
              );
            },
            child: const Text("View Instructions"),
          ),
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConditionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}