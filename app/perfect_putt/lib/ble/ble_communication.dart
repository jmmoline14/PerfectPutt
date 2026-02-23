import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../putting_metrics/putting_metrics.dart';


/// UUIDs for the Portenta H7 camera stream.
Guid kCameraServiceUuid = Guid("00000000-0000-0000-0000-000000000001");
Guid kCameraCharUuid = Guid("00000000-0000-0000-0000-000000000002");
Guid kimuServiceUuid = Guid("0075");
Guid kimuCharUuid = Guid("0075");
Guid kPuttingServiceUuid = Guid("0075");
Guid kPuttingCharUuid = Guid("0075");


class BleCommunication {
  BluetoothDevice? connectedDevice;
  List<BluetoothService> _services = [];

  BluetoothCharacteristic? _cameraChar;
  BluetoothCharacteristic? _imuChar;
  BluetoothCharacteristic? _puttingChar;

  
  StreamSubscription<List<int>>? _imuSub;
  StreamSubscription<List<int>>? _cameraSub;
  StreamSubscription<List<int>>? _puttingSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _mockCameraTimer;

  final List<BluetoothDevice>devicesList = [];

  // Get member variables
  BluetoothCharacteristic? getPuttingChar() {
    return _puttingChar;
  }

  // Scanning
  Future<void> startScan(Function(List<BluetoothDevice>) onDevicesUpdated,) async {
    devicesList.clear();
    _scanSub?.cancel();

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        if (!devicesList.contains(result.device)) {
          devicesList.add(result.device);
        }
      }
      onDevicesUpdated(devicesList);
    });

    await FlutterBluePlus.startScan();
  }

  // Connecting
  Future<void> connect(
    BluetoothDevice device, {
    required Function(List<BluetoothService>) onServicesReady,
    required Function(PuttingMetrics) onMetricsReceived,
    required Function(Uint8List) onFrameReceived,
  }) async {
    FlutterBluePlus.stopScan();

    try {
      await device.connect();
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    }

    connectedDevice = device;
    _services = await device.discoverServices();

    onServicesReady(_services);

    await _attachPutting(onMetricsReceived);
    await _attachCamera(onFrameReceived);
  }

  // IMU
  Future<void> _attachPutting(
    Function(PuttingMetrics) onMetricsReceived,
  ) async {
    for (final service in _services) {
      if (service.uuid == kimuServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == kimuCharUuid) {
            _puttingChar = characteristic;
          }
        }
      }
    }

    if (_puttingChar == null) return;

    _puttingSub = _puttingChar!.lastValueStream.listen((value) {
      final metrics = PuttingMetrics.fromBytes(value);
      onMetricsReceived(metrics);
    });

    await _puttingChar!.setNotifyValue(true);
  }
  
  // Camera
  Future<void> _attachCamera(
    Function(Uint8List) onFrameReceived,
  ) async {
    for (final service in _services) {
      if (service.uuid == kCameraServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == kCameraCharUuid) {
            _cameraChar = characteristic;
          }
        }
      }
    }

    if (_cameraChar == null) return;

    _cameraSub = _cameraChar!.lastValueStream.listen((value) {
      onFrameReceived(Uint8List.fromList(value));
    });

    await _cameraChar!.setNotifyValue(true);
  }

  // Request Frame
  Future<void> requestFrame() async {
    if (_cameraChar == null) return;

    if (_cameraChar!.properties.write ||
        _cameraChar!.properties.writeWithoutResponse) {
      await _cameraChar!.write(
        [0x01],
        withoutResponse:
            _cameraChar!.properties.writeWithoutResponse &&
            !_cameraChar!.properties.write,
      );
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    await _puttingSub?.cancel();
    await _cameraSub?.cancel();
    await _scanSub?.cancel();

    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }

    connectedDevice = null;
    _services.clear();
  }
}

