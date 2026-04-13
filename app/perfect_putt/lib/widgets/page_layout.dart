import 'package:flutter/material.dart';
import 'home_button.dart';

class PageLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const PageLayout({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [HomeButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}