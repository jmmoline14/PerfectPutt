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

Guid preSwingDataServiceUuid = Guid("0075");
Guid preSwingDataCharUuid = Guid("0081");
Guid postSwingDataServiceUuid = Guid("0075");
Guid postSwingDataCharUuid = Guid("0080");



class BleCommunication {
  BluetoothDevice? connectedDevice;
  List<BluetoothService> _services = [];

  BluetoothCharacteristic? _cameraChar;
  BluetoothCharacteristic? _preSwingDataChar;
  BluetoothCharacteristic? _postSwingDataChar;

  
  StreamSubscription<List<int>>? _cameraSub;
  StreamSubscription<List<int>>? _preSwingDataSub;
  StreamSubscription<List<int>>? _postSwingDataSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _mockCameraTimer;

  final List<BluetoothDevice>devicesList = [];

  // Get member variables
  BluetoothCharacteristic? getPreSwingDataChar() {
    return _preSwingDataChar;
  }
  
  BluetoothCharacteristic? getPostSwingDataChar() {
    return _postSwingDataChar;
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
    required Function(List<int>) onPreSwingReceived,
    required Function(List<int>) onPostSwingReceived,
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

    await _attachPreSwingData(onPreSwingReceived);
    await _attachPostSwingData(onPostSwingReceived);
    await _attachCamera(onFrameReceived);
  }

  // Pre-swing data
  Future<void> _attachPreSwingData(
    Function(List<int>) onPreSwingReceived,
  ) async {
    for (final service in _services) {
      if (service.uuid == preSwingDataServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == preSwingDataCharUuid) {
            _preSwingDataChar = characteristic;
          }
        }
      }
    }

    if (_preSwingDataChar == null) return;

    _preSwingDataSub = _preSwingDataChar!.lastValueStream.listen((value) {
      final metricsBytes = value;
      onPreSwingReceived(metricsBytes);
    });

    await _preSwingDataChar!.setNotifyValue(true);
  }

  // Post-swing data
  Future<void> _attachPostSwingData(
    Function(List<int>) onPostSwingReceived,
  ) async {
    for (final service in _services) {
      if (service.uuid == postSwingDataServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == postSwingDataCharUuid) {
            _postSwingDataChar = characteristic;
          }
        }
      }
    }

    if (_postSwingDataChar == null) return;

    _postSwingDataSub = _postSwingDataChar!.lastValueStream.listen((value) {
      final metricsBytes = value;
      onPostSwingReceived(metricsBytes);
    });

    await _postSwingDataChar!.setNotifyValue(true);
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
    await _preSwingDataSub?.cancel();
    await _postSwingDataSub?.cancel();
    await _cameraSub?.cancel();
    await _scanSub?.cancel();

    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }

    connectedDevice = null;
    _services.clear();
  }
}

