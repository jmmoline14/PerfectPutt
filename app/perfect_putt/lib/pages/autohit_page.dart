import 'package:flutter/material.dart';
import 'package:perfect_putt/pages/home_page.dart';
import '../widgets/page_layout.dart';

class AutohitPage extends StatelessWidget {
  const AutohitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Auto-hit",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Follow these instructions to use auto-hit"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}