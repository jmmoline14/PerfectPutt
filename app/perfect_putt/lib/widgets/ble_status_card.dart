import 'package:flutter/material.dart';
import '../ble/ble_service.dart';
import '../globals/globals.dart';

class BleStatusCard extends StatelessWidget {
  const BleStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = BleService();

    return ValueListenableBuilder(
      valueListenable: ble.connectedDeviceNotifier,
      builder: (context, device, _) {
        final isConnected = device != null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? greenColor
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? "Device Connected" : "No Device Connected",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isConnected
                              ? (device.platformName.isNotEmpty
                                  ? device.platformName
                                  : "PerfectPutt Device")
                              : "Connect your PerfectPutt device via Bluetooth",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Bluetooth icon
                  Icon(
                    Icons.bluetooth,
                    color: isConnected
                        ? greenColor
                        : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}