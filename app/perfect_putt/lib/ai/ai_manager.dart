import 'dart:async';
import 'dart:typed_data';

class PuttingMetrics {
  final double putterToHoleDist;
  final double ballToHoleDist;
  final double holeCenterOffset;
  final double swingForce;
  final double swingAngle;
  final double followThroughDeg;

  // Constructor
  const PuttingMetrics({
    required this.putterToHoleDist,
    required this.ballToHoleDist,
    required this.holeCenterOffset,
    required this.swingForce,
    required this.swingAngle,
    required this.followThroughDeg,
  });

  // Encode data for training

  // Encode data into CSV
  String metricsToCsv(List<PuttingMetrics> metrics) {
    final buffer = StringBuffer();
    buffer.writeln("putterToHoleDist,ballToHoleDist,holeCenterOffset,swingForce,swingAngle,followThroughDeg");

    for (final metric in metrics) {
      buffer.writeln("${metric.putterToHoleDist}");
      buffer.writeln("${metric.ballToHoleDist}");
      buffer.writeln("${metric.holeCenterOffset}");
      buffer.writeln("${metric.swingForce}");
      buffer.writeln("${metric.swingAngle}");
      buffer.writeln("${metric.followThroughDeg}");
    }

    return buffer.toString();
  }

  // Send data over email
  

  // Decode Bluetooth data
  static PuttingMetrics fromBytes(List<int> bytes) {
    if (bytes.length < 25) {
      throw ArgumentError("BLE Packet not large enough");
    }

    final data = ByteData.sublistView(Uint8List.fromList(bytes));

    return PuttingMetrics(
      putterToHoleDist: data.getFloat32(1, Endian.little),
      ballToHoleDist: data.getFloat32(5, Endian.little),
      holeCenterOffset: data.getFloat32(9, Endian.little),
      swingForce: data.getFloat32(13, Endian.little),
      swingAngle: data.getFloat32(17, Endian.little),
      followThroughDeg: data.getFloat32(21, Endian.little),
    );
  }
}