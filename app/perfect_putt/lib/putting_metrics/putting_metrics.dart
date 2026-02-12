import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

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

  // Send data for training

  // Encode data into CSV
  static String metricsToCsv(List<PuttingMetrics> metrics) {
    final buffer = StringBuffer();
    buffer.writeln(
      "putterToHoleDist,holeCenterOffset,ballToHoleDistX,ballToHoleDistY,"
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

  // Send data over email


  // Decode Bluetooth data
  static PuttingMetrics fromBytes(List<int> bytes) {
    if (bytes.length < 29) {
      throw ArgumentError("BLE Packet not large enough");
    }

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final ballToHoleX = data.getFloat32(9, Endian.little);
    final ballToHoleY = data.getFloat32(13, Endian.little);

    bool successful = false;
    if (ballToHoleX == 0 && ballToHoleY == 0) {
      successful = true;
    }

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