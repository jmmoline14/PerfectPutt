import 'package:flutter/material.dart';
import 'instructions_page.dart';
import '../widgets/page_layout.dart';
import '../globals/globals.dart';
import '../widgets/feedback_card.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final m = currMetricsGlobal;
    final f = currFeedback;

    return PageLayout(
      title: "Feedback",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Putt result
            Text(
              f.resultsMessage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // All feedback
            FeedbackCard(
              label: "Direction",
              value: m.direction,
              minOk: 0.1,
              maxOk: 0.9,
              message: f.directionMessage,
            ),
            
            FeedbackCard(
              label: "Impact",
              value: m.impact,
              minOk: 5.0,
              maxOk: 15.0,
              message: f.impactMessage,
            ),

            FeedbackCard(
              label: "Follow Through",
              value: m.followThroughDeg,
              minOk: 40.0,
              maxOk: 80.0,
              message: f.followThroughMessage,
            ),

            FeedbackCard(
              label: "Tempo",
              value: m.tempo,
              minOk: 0.4,
              maxOk: 0.6,
              message: f.tempoMessage,
            ),

            FeedbackCard(
              label: "Stability",
              value: m.stability,
              minOk: 0.0,
              maxOk: 15.0,
              message: f.stabilityMessage,
            ),

            FeedbackCard(
              label: "Straightness",
              value: m.straightness,
              minOk: 0.0,
              maxOk: 3.0,
              message: f.straightnessMessage,
            ),

            const SizedBox(height: 20),

            const Text("Click below to swing again."),

            const SizedBox(height: 20),

            // Swing again button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InstructionsPage(),
                    ),
                  );
                },
                child: const Text("Swing Again"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}