// lib/services/ble_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:perfect_putt/globals/globals.dart';
import 'ble_communication.dart';
import '../putting_metrics/putting_metrics.dart';

class BleService {
  // Singleton pattern
  static final BleService _instance = BleService._internal();

  // BLE state
  final ValueNotifier<BluetoothDevice?> connectedDeviceNotifier =
    ValueNotifier<BluetoothDevice?>(null);
  
  List<BluetoothService> myServices = [];
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
  
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
    await _ble.startScan((devices) {
      devicesList.clear();
      devicesList.addAll(devices);
      onDevicesUpdated(devicesList);
    });
  }

  // Connect to a device
  Future<void> connect(BluetoothDevice device, VoidCallback? onUpdated) async {
    await _ble.connect(
      device,
      onServicesReady: (services) {
        myServices.clear();
        myServices.addAll(services);

        connectedDeviceNotifier.value = device;

        onUpdated?.call();
        print("Services discovered: ${services.length}");
      },
      onPreSwingReceived: (bytes) {
        // Handles all data now
        try {
          currMetrics.updateMetrics(bytes);
          currMetricsGlobal = currMetrics.copy();
          print("Metrics updated: ${currMetrics.impact}");
        } catch (e) {
          print("Error updating metrics: $e");
        }
      },
      onPostSwingReceived: (bytes) {}, // Not using
      onFrameReceived: (frame) {}, // Not using
    );
  }

  // Disconnect from device
  Future<void> disconnect() async {
    await _ble.disconnect();
    connectedDeviceNotifier.value = null;
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
  // Also not using
  Future<void> requestFrame() async {
    await _ble.requestFrame();
  }
}