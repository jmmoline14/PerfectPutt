// lib/pages/bluetooth_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ble/ble_service.dart';
import '../widgets/page_layout.dart';

class NewBluetoothPage extends StatefulWidget {
  const NewBluetoothPage({super.key});

  @override
  State<NewBluetoothPage> createState() => _NewBluetoothPageState();
}



class _NewBluetoothPageState extends State<NewBluetoothPage> {
  final BleService bleService = BleService();

  // Build page view of devices
  ListView _buildConnectDeviceView() {
    final List<Widget> containers = <Widget>[];

    for (BluetoothService service in bleService.myServices) {
      final List<Widget> characteristicsWidget = <Widget>[];

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        characteristic.uuid.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ..._buildReadWriteNotifyButtons(characteristic),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Value: ${bleService.readValues[characteristic.uuid]}',
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
        );
      }

      containers.add(
        ExpansionTile(
          title: Text(service.uuid.toString()),
          children: characteristicsWidget,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[...containers],
    );
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  ListView _buildListViewOfDevices() {
    final List<Widget> containers = <Widget>[];

    for (BluetoothDevice device in bleService.devicesList) {
      if (device.platformName == "PERFECTPUTT") {
        containers.add(
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(
                device.advName.isEmpty
                    ? (device.platformName.isEmpty
                        ? '(unknown device)'
                        : device.platformName)
                    : device.advName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(device.remoteId.toString()),
              trailing: TextButton(
                child: const Text('Connect'),
                onPressed: () {
                  bleService.connect(device, () {
                    setState(() {});
                  });
                },
              ),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[...containers],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButtons(
      BluetoothCharacteristic characteristic) {
    final List<ButtonTheme> buttons = <ButtonTheme>[];

    // READ
    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child: const Text('READ', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                final sub = characteristic.lastValueStream.listen((value) {
                  setState(() {
                    bleService.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                await sub.cancel();
              },
            ),
          ),
        ),
      );
    }

    // NOTIFY
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child:
                  const Text('NOTIFY', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                characteristic.lastValueStream.listen((value) {
                  setState(() {
                    bleService.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  Widget _buildView() {
    final device = bleService.connectedDevice;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // STATUS
        Text(
          device != null
              ? "Connected to ${device.platformName.isNotEmpty ? device.platformName : "Device"}"
              : "No device connected",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 20),

        // CONNECT / DISCONNECT ACTIONS
        if (device == null)
          ElevatedButton(
            onPressed: () async {
              await requestPermissions();
              bleService.startScan((devices) {
                setState(() {});
              });
            },
            child: const Text('Scan for Devices'),
          ),

        if (device != null)
          ElevatedButton(
            onPressed: () async {
              await bleService.disconnect();
              setState(() {});
            },
            child: const Text('Disconnect'),
          ),

        const SizedBox(height: 20),

        // DEVICE LIST (ONLY WHEN NOT CONNECTED)
        if (device == null)
          Expanded(
            child: _buildListViewOfDevices(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = bleService.connectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth")
      ),
      body: SafeArea(
        child: _buildView(),
      ),
    );
  }
}