import 'package:flutter/material.dart';

class FeedbackCard extends StatelessWidget {
  final String label;
  final double value;
  final double minOk;
  final double maxOk;
  final String message;

  const FeedbackCard({
    super.key,
    required this.label,
    required this.value,
    required this.minOk,
    required this.maxOk,
    required this.message,
  });
  double get buffer => (maxOk - minOk) * 0.2;

  double get minBound => minOk - buffer;
  double get maxBound => maxOk + buffer;

  bool get isGreen => value >= minOk && value <= maxOk;
  bool get isYellow => !isGreen && (value >= minBound) && (value <= maxBound);
  bool get isRed => !isGreen && !isYellow;

  String get statusLabel {
    if (isGreen) return "GOOD";
    if (isYellow) return "ALMOST";
    return "OFF TARGET";
  }

  Color get statusColor {
    if (isGreen) return Colors.green;
    if (isYellow) return Colors.orange;
    return Colors.red;
  }

  double get barPercent {
    // normalize across FULL range (yellow included)
    final normalized =
        (value - minBound) / (maxBound - minBound);

    if (isRed) {
      // clamp red extremes
      return value <= minBound
          ? 0.0
          : 1.0;
    }

    // yellow + green both map smoothly
    return normalized.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Color bar
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

                FractionallySizedBox(
                  widthFactor: barPercent,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Feedback message
            Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}