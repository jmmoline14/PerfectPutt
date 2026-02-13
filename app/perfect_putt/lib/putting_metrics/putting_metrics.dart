import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

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
  static Future<bool> exportMetrics(List<PuttingMetrics> metrics, String subject, String emailAddr) async {
    String filePath = await PuttingMetrics.createCsvFile(metrics);

    // Create email
    final Email email = Email(
      body: "",
      subject: subject,
      recipients: [emailAddr],
      attachmentPaths: [filePath],
    );

    // Send email
    bool sentSuccessfully = true;
    try {
      await FlutterEmailSender.send(email);
      print("Successful email");
    } catch (error) {
      sentSuccessfully = false;
      print("failed to email: $error");
    }

    return sentSuccessfully;
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
    if (bytes.length < 29) {
      throw ArgumentError("BLE Packet not large enough");
    }

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final ballToHoleX = data.getFloat32(9, Endian.little);
    final ballToHoleY = data.getFloat32(13, Endian.little);

    bool successful = ballToHoleX.abs() < 1e-6 && ballToHoleY.abs() < 1e-6;

    return PuttingMetrics(
      putterToHoleDist: data.getFloat32(1, Endian.little),
      holeCenterOffset: data.getFloat32(5, Endian.little),
      ballToHoleDistX: ballToHoleX,
      ballToHoleDistY: ballToHoleY,
      swingForce: data.getFloat32(17, Endian.little),
      putterAngle: data.getFloat32(21, Endian.little),
      followThroughDeg: data.getFloat32(25, Endian.little),
      successfulShot: successful,
    );
  }
}