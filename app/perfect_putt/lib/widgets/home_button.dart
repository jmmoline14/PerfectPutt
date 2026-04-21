import 'package:flutter/material.dart';
import '../globals/globals.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.home_rounded,
        size: 24,
        color: backgroundColor,
      ),
      splashRadius: 22,
      onPressed: () {
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }
}