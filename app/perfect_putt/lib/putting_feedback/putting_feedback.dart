import 'dart:math';
import '../putting_metrics/putting_metrics.dart';

class PuttingFeedback {
  String resultsMessage;
  String impactMessage;
  String followThroughMessage;
  String tempoMessage;
  String stabilityMessage;
  String straightnessMessage;
  String directionMessage;
  String dataSummary;
  bool ballDetected;
  
  PuttingFeedback({
    required this.resultsMessage,
    required this.impactMessage,
    required this.followThroughMessage,
    required this.tempoMessage,
    required this.stabilityMessage,
    required this.straightnessMessage,
    required this.directionMessage,
    required this.dataSummary,
    required this.ballDetected,
  });

  void updateFeedbackFromMetrics(PuttingMetrics metrics) {
    bool perfectPutt = true;

    // impact
    if (metrics.impact < 5.0) {
      impactMessage = "Try to hit the ball a little harder.";
      perfectPutt = false;
    } else if (metrics.impact > 15.0) {
      impactMessage = "Try to hit the ball a little softer.";
      perfectPutt = false;
    } else {
      impactMessage = "Great impact!";
    }

    // Follow-through
    if (metrics.followThroughDeg < 40.0) {
      followThroughMessage = "After making contact with the ball, make sure you follow through with your swing.";
      perfectPutt = false;
    } else if (metrics.followThroughDeg > 80.0) {
      followThroughMessage = "After making contact with the ball, try to follow through less.";
      perfectPutt = false;
    } else {
      followThroughMessage = "Great follow-through!";
    }

    // Tempo
    if (metrics.tempo < 0.4) {
      tempoMessage = "Try to swing a little faster.";
      perfectPutt = false;
    } else if (metrics.tempo > 0.6) {
      tempoMessage = "Try to swing a little slower.";
      perfectPutt = false;
    } else {
      tempoMessage = "Great tempo!";
    }

    // Stability
    if (metrics.stability < 0.0 || metrics.stability > 15.0) {
      stabilityMessage = "Try to keep your putter more stable during the swing.";
      perfectPutt = false;
    } else {
      stabilityMessage = "Great stability!";
    }

    // Straightness
    if (metrics.straightness < 0.0 || metrics.straightness > 3.0) {
      straightnessMessage = "Your swing was a little wobbly, try to swing in a straighter path.";
      perfectPutt = false;
    } else {
      straightnessMessage = "Great straightness!";
    }

    // Direction
    ballDetected = true;
    if (metrics.direction > 0.9) {
      directionMessage = "Try to aim a little more to the left.";
      perfectPutt = false;
    } else if (metrics.direction < 0.1) {
      directionMessage = "Try to aim a little more to the right.";
      perfectPutt = false;
    } else if (metrics.successfulShot){
      directionMessage = "You hit the ball spot on!";
    } else {
      directionMessage = "Error: ball not detected in frame";
      ballDetected = false;
    }

    // Results Message
    if (perfectPutt) {
      resultsMessage = "Wow! Perfect putt!";
    } else if (metrics.successfulShot) {
      resultsMessage = "Great job! You made it! Here are some suggestions to make it even better.";
    } else {
      resultsMessage = "Almost there! Here are some suggestions for improvement.";
    }

    // Data Summary (for debugging)
    dataSummary = """
      Data Summary
      ━━━━━━━━━━━━━━━━━━━━
      Impact: ${metrics.impact.toStringAsFixed(2)}
      Follow Through: ${metrics.followThroughDeg.toStringAsFixed(1)}
      Tempo: ${metrics.tempo.toStringAsFixed(2)}
      Stability: ${metrics.stability.toStringAsFixed(2)}
      Straightness: ${metrics.straightness.toStringAsFixed(2)}
      Direction: ${metrics.direction.toStringAsFixed(1)}
      Successful Shot: ${metrics.successfulShot}
      """;
  }
}