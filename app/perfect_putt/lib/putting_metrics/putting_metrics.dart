import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PuttingMetrics {
  final double putterToHoleDist;
  final double holeCenterOffset;
  final double ballToHoleDistX;
  final double ballToHoleDistY;
  final double swingForce;
  final double putterAngle;
  final double followThroughDeg;
  final bool   successfulShot;

  // Constructor
  const PuttingMetrics({
    required this.putterToHoleDist,
    required this.holeCenterOffset,
    required this.ballToHoleDistX,
    required this.ballToHoleDistY,
    required this.swingForce,
    required this.putterAngle,
    required this.followThroughDeg,
    required this.successfulShot,
  });

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
      "putterToHoleDist,ballToHoleDistX,ballToHoleDistY,holeCenterOffset,"
      "swingForce,putterAngle,followThroughDeg,successfulShot"
    );

    for (final metric in metrics) {
      buffer.writeln(
        "${metric.putterToHoleDist},"
        "${metric.ballToHoleDistX},"
        "${metric.ballToHoleDistY},"
        "${metric.holeCenterOffset},"
        "${metric.swingForce},"
        "${metric.putterAngle},"
        "${metric.followThroughDeg},"
        "${metric.successfulShot ? 1 : 0}"
      );
    }

    return buffer.toString();
  }

  // Decode Bluetooth data
  static PuttingMetrics fromBytes(List<int> bytes) {
    if (bytes.length < 28) {
      print("Error, incorrect size packet");
      throw ArgumentError("BLE Packet not large enough");
    } else {
      print("Successful packet transmission!");
    }

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final ballToHoleX = data.getFloat32(8, Endian.little);
    final ballToHoleY = data.getFloat32(12, Endian.little);

    bool successful = ballToHoleX.abs() < 1e-6 && ballToHoleY.abs() < 1e-6;

    return PuttingMetrics(
      putterToHoleDist: data.getFloat32(0, Endian.little),
      holeCenterOffset: data.getFloat32(4, Endian.little),
      ballToHoleDistX: ballToHoleX,
      ballToHoleDistY: ballToHoleY,
      swingForce: data.getFloat32(16, Endian.little),
      putterAngle: data.getFloat32(20, Endian.little),
      followThroughDeg: data.getFloat32(24, Endian.little),
      successfulShot: successful,
    );
  }
}