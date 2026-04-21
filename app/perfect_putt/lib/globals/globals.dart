import 'package:flutter/material.dart';
import '../putting_metrics/putting_metrics.dart';
import '../putting_feedback/putting_feedback.dart';


const greenColor = Color(0xFF1B5E20); // Green color
const accentColor = Color(0xFF2D9CDB); // Blue color
const backgroundColor = Color(0xFFF5F5F5); // Light grey color

PuttingMetrics currMetricsGlobal = PuttingMetrics(
  impact: 0.0,
  followThroughDeg: 0.0,
  tempo: 0.0,
  stability: 0.0,
  straightness: 0.0,
  direction: 0.0,
  successfulShot: false,
);

PuttingFeedback currFeedback = PuttingFeedback(
  resultsMessage: "No feedback available yet.",
  impactMessage: "No feedback available yet.",
  followThroughMessage: "No feedback available yet.",
  tempoMessage: "No feedback available yet.",
  stabilityMessage: "No feedback available yet.",
  straightnessMessage: "No feedback available yet.",
  directionMessage: "No feedback available yet.",
  dataSummary: "No feedback available yet.",
  ballDetected: true,
);

