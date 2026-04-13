// lib/services/ble_service.dart
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_communication.dart';
import '../putting_metrics/putting_metrics.dart';

class BleService {
  // Singleton pattern
  static final BleService _instance = BleService._internal();
  
  factory BleService() {
    return _instance;
  }
  
  BleService._internal();

  // BLE communication handler
  final BleCommunication _ble = BleCommunication();

  // Current metrics being collected
  PuttingMetrics currMetrics = PuttingMetrics(
    impact: 0,
    followThroughDeg: 0,
    tempo: 0,
    stability: 0,
    straightness: 0,
    direction: 0,
    successfulShot: false,
  );

  // Storage for all collected metrics
  final List<PuttingMetrics> metricsHistory = [];

  // Expose connected device
  BluetoothDevice? get connectedDevice => _ble.connectedDevice;

  // Start scanning for devices
  Future<void> startScan(void Function(List<BluetoothDevice>) onDevicesUpdated) async {
    await _ble.startScan(onDevicesUpdated);
  }

  // Connect to a device
  Future<void> connect(BluetoothDevice device) async {
    await _ble.connect(
      device,
      onServicesReady: (services) {
        print("Services discovered: ${services.length}");
      },
      onPreSwingReceived: (bytes) {
        // Handle your single data stage here
        try {
          currMetrics.updateMetrics(bytes);
          print("Metrics updated: ${currMetrics.impact}");
        } catch (e) {
          print("Error updating metrics: $e");
        }
      },
      onPostSwingReceived: (bytes) {
        // If you're not using this anymore, you can leave it empty
        // or remove it from BleCommunication entirely
      },
      onFrameReceived: (frame) {
        // Handle camera frames if needed
      },
    );
  }

  // Disconnect from device
  Future<void> disconnect() async {
    await _ble.disconnect();
  }

  // Save current metrics to history
  void saveCurrentMetrics() {
    metricsHistory.add(currMetrics.copy());
  }

  // Reset current metrics
  void resetCurrentMetrics() {
    currMetrics = PuttingMetrics(
      impact: 0,
      followThroughDeg: 0,
      tempo: 0,
      stability: 0,
      straightness: 0,
      direction: 0,
      successfulShot: false,
    );
  }

  // Export all metrics
  Future<void> exportMetrics(String subject) async {
    await PuttingMetrics.exportMetrics(metricsHistory, subject);
  }

  // Clear all history
  void clearHistory() {
    metricsHistory.clear();
  }

  // Request a camera frame
  Future<void> requestFrame() async {
    await _ble.requestFrame();
  }
}