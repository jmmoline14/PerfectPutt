import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';


/// UUIDs for the Portenta H7 camera stream.
Guid kCameraServiceUuid = Guid("00000000-0000-0000-0000-000000000001");
Guid kCameraCharUuid = Guid("00000000-0000-0000-0000-000000000002");
Guid kimuServiceUuid = Guid("0075");
Guid kimuCharUuid = Guid("0080");
Guid kPuttingServiceUuid = Guid("0075");
Guid kPuttingCharUuid = Guid("0080");


class BleCommunication {
  BluetoothDevice? connectedDevice;
  List<BluetoothService> _services = [];

  BluetoothCharacteristic? _cameraChar;
  BluetoothCharacteristic? _puttingChar;

  
  StreamSubscription<List<int>>? _imuSub;
  StreamSubscription<List<int>>? _cameraSub;
  StreamSubscription<List<int>>? _puttingSub;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _mockCameraTimer;

  
}



// Decode IMU Data into arrays of doubles
bool decodeIMUData(List<int> value, 
                    List<double> accelData, 
                    List<double> gyroData, 
                    List<double> magData) {
  // Check that packet is correct size
  int idealPacketSize = 25; // Mag data not currently used
  if (value.length < idealPacketSize) return false;

  // Convert to ByteData object
  final byteData = ByteData.sublistView(
    Uint8List.fromList(value),
  );

  // Accel data
  accelData[0] = byteData.getFloat32(1, Endian.little);
  accelData[1] = byteData.getFloat32(5, Endian.little);
  accelData[2] = byteData.getFloat32(9, Endian.little);

  // Gyro data
  gyroData[0] = byteData.getFloat32(13, Endian.little);
  gyroData[1] = byteData.getFloat32(17, Endian.little);
  gyroData[2] = byteData.getFloat32(21, Endian.little);

  // Don't update mag data

  return true;
}