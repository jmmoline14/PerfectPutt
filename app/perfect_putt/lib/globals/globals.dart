import '../putting_metrics/putting_metrics.dart';
import '../putting_feedback/putting_feedback.dart';

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
  resultsMessage: "",
  impactMessage: "",
  followThroughMessage: "",
  tempoMessage: "",
  stabilityMessage: "",
  straightnessMessage: "",
  directionMessage: "",
  dataSummary: "",
  ballDetected: true,
);

