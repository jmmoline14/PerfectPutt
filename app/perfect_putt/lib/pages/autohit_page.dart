import 'package:flutter/material.dart';
import '../widgets/page_layout.dart';
import '../widgets/step_card.dart';

class AutohitPage extends StatelessWidget {
  const AutohitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Auto-Hit Instructions",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Follow these steps to use Auto-Hit mode with your PerfectPutt device.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 20),

          StepCard(
            number: "1",
            title: "Enter Auto-Hit Mode",
            description:
                "Ensure the device LED is green. Hold the bottom button for 3 seconds to switch modes if needed.",
          ),

          StepCard(
            number: "2",
            title: "Set Up Your Putt",
            description:
                "Make sure the PerfectPutt device is securely attached to your putter, and place the ball on the green. Align yourself behind the ball.",
          ),

          StepCard(
            number: "3",
            title: "Set Distance",
            description:
                "Measure the distance to the hole in feet, then tap the bottom button that many times to set it.",
          ),

          StepCard(
            number: "4",
            title: "Execute Auto-Hit",
            description:
                "Press the top button to trigger the automatic putt.",
          ),
        ],
      ),
    );
  }
}