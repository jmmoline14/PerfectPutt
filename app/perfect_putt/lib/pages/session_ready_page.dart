import 'package:flutter/material.dart';
import 'feedback_page.dart';
import '../widgets/page_layout.dart';
import '../ble/ble_service.dart';
import '../globals/globals.dart';

class SessionReadyPage extends StatelessWidget {
  const SessionReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BleService bleService = BleService();

    return PageLayout(
        title: "Get Ready",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Get into position and swing the putter. After your swing is complete, return to neutral position and hold for a few seconds while we scan. Then click Swing Complete"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              bleService.saveCurrentMetrics();
              currFeedback.updateFeedbackFromMetrics(bleService.currMetrics);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackPage()),
              );
            },
            child: const Text("Swing Complete"),
          ),
        ],
      ),
    );
  }
}

