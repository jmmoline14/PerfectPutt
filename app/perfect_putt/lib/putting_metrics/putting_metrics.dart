import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PuttingMetrics {
  double impact;
  double followThroughDeg;
  double tempo;
  double stability;
  double straightness;
  double direction;
  bool   successfulShot;

  // Constructor
  PuttingMetrics({
    required this.impact,
    required this.followThroughDeg,
    required this.tempo,
    required this.stability,
    required this.straightness,
    required this.direction,
    required this.successfulShot,
  });

  // Copier
  PuttingMetrics copy() {
    return PuttingMetrics(
      impact: impact,
      followThroughDeg: followThroughDeg,
      tempo: tempo,
      stability: stability,
      straightness: straightness,
      direction: direction,
      successfulShot: successfulShot,
    );
  }

  // Export data for training
  static Future<void> exportMetrics(List<PuttingMetrics> metrics, String subject) async {
    String filePath = await PuttingMetrics.createCsvFile(metrics);

    // Share file
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
    );
  }

  // Create CSV file
  // Returns file path
  static Future<String> createCsvFile(List<PuttingMetrics> metrics) async {
    final csvStr = metricsToCsvStr(metrics);

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/putting_metrics.csv";
    
    final File file = await File(filePath).create(recursive:true);
    await file.writeAsString(csvStr);

    return filePath;
  }

  // Encode data into CSV string
  static String metricsToCsvStr(List<PuttingMetrics> metrics) {
    final buffer = StringBuffer();
    buffer.writeln(
      "impact, followThroughDeg, tempo, stability, straightness, direction, successfulShot"
    );

    for (final metric in metrics) {
      buffer.writeln(
        "${metric.impact},"
        "${metric.followThroughDeg},"
        "${metric.tempo},"
        "${metric.stability},"
        "${metric.straightness},"
        "${metric.direction},"
        "${metric.successfulShot ? 1 : 0}"
      );
    }

    return buffer.toString();
  }


  // Updata putting metrics
  void updateMetrics(List<int> bytes) {
    if (bytes.length < 28) {
      print("Error, incorrect size packet");
      throw ArgumentError("BLE Packet not large enough");
    } else {
      print("Successful packet transmission!");
    }

    final data = ByteData.sublistView(Uint8List.fromList(bytes));

    impact = data.getFloat32(0, Endian.little);
    followThroughDeg = data.getFloat32(4, Endian.little);
    tempo = data.getFloat32(4, Endian.little);
    stability = data.getFloat32(4, Endian.little);
    straightness = data.getFloat32(4, Endian.little);
    direction = data.getFloat32(4, Endian.little);
    double successfulShotBytes = data.getFloat32(4, Endian.little);

    successfulShot = successfulShotBytes > 0.99;

    return;
  }
}