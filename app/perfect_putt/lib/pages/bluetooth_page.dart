// lib/pages/bluetooth_page.dart
import 'package:flutter/material.dart';
import '../ble/ble_service.dart';
import '../widgets/page_layout.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final BleService bleService = BleService();

  @override
  Widget build(BuildContext context) {
    final connectedDevice = bleService.connectedDevice;

    return PageLayout(
      title: "Bluetooth",
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 👈 prevents full-height stretching
          children: [
            Text(
              connectedDevice != null
                  ? "Connected to ${connectedDevice.name}"
                  : "No device connected",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: 200, // 👈 consistent button width
              child: ElevatedButton(
                onPressed: connectedDevice == null
                    ? null // 👈 disables button when not connected
                    : () async {
                        await bleService.disconnect();
                        setState(() {});
                      },
                child: const Text("Disconnect"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: trigger scan or navigate
                },
                child: const Text("Scan for devices"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}