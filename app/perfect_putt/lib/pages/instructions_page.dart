import 'package:flutter/material.dart';
import 'package:perfect_putt/pages/feedback_page.dart';
import '../widgets/page_layout.dart';
import '../widgets/step_card.dart';
import '../ble/ble_service.dart';
import '../globals/globals.dart';
import '../putting_metrics/putting_metrics.dart';

void loadMockSwing() {
  currMetricsGlobal = PuttingMetrics(
    impact: 10.0,
    followThroughDeg: 41.0,
    tempo: 0.59,
    stability: -0.2,
    straightness: 3.1,
    direction: 1.5,
    successfulShot: false,
  );
}

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bleService = BleService();
    final isConnected = bleService.connectedDevice != null;

    return PageLayout(
      title: "Instructions",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Complete the following steps to start a putting session with PerfectPutt.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 20),

            StepCard(
              number: "1",
              title: "Enter Practice Mode",
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
              title: "Execute the Stroke",
              description:
                  "Putt the ball, and return the putter to its starting position. The LED will flash blue while processing and turn orange when data has been sent.",
            ),

            StepCard(
              number: "4",
              title: "Processing",
              description:
                  "Hold the putter in its starting position until the LED is orange. When that happens, click below to view your feedback.",
            ),

            const SizedBox(height: 10),

            if (!isConnected)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "You must be connected to a PerfectPutt device in order to continue.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isConnected
                    ? () {
                        // Mock data for debugging
                        //loadMockSwing();

                        // Update feedback
                        currFeedback.updateFeedbackFromMetrics(currMetricsGlobal);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeedbackPage(),
                          ),
                        );
                      }
                    : null, /// Disable button if not connected to device
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isConnected ? null : Colors.grey.shade400,
                ),
                child: const Text("Swing Complete"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}