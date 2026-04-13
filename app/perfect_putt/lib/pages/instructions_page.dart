import 'package:flutter/material.dart';
import 'session_ready_page.dart';
import '../widgets/home_button.dart';
import '../widgets/page_layout.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Instructions",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Position your putter behind the golf ball preparing to hit it."),
          const Text("Ensure the putter is facing the hole."),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SessionReadyPage()),
              );
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}