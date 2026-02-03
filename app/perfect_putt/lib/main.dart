import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Toggle this for dev:
/// true  = use fake/mock device (no real BLE needed)
/// false = use real Arduino Portenta H7 over BLE
const bool kUseMockDevice = true;

/// UUIDs for the Portenta H7 camera stream.
/// TODO: replace these with your real service/characteristic UUIDs.
Guid kCameraServiceUuid = Guid("00000000-0000-0000-0000-000000000001");
Guid kCameraCharUuid = Guid("00000000-0000-0000-0000-000000000002");
Guid kimuServiceUuid = Guid("0075");
Guid kimuCharUuid = Guid("0080");

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


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Perfect Putt',
        theme: ThemeData(
          primarySwatch: Colors.lightGreen,
        ),
        home: MyHomePage(title: 'Perfect Putt'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final TextEditingController _writeController = TextEditingController();

  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];

  // Camera feed state
  Uint8List? _latestFrame;
  StreamSubscription<List<int>>? _cameraSub;
  //Camera Request
  BluetoothCharacteristic? _cameraChar;
  // IMU Data state
  List<String> _accelData = List.filled(3, "N/A");
  List<String> _gyroData  = List.filled(3, "N/A");
  List<String> _magData   = List.filled(3, "N/A");
  StreamSubscription<List<int>>? _imuSub;

  // BLE scanning
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Mock mode
  bool _isMock = kUseMockDevice;
  Timer? _mockCameraTimer;

  @override
  void initState() {
    super.initState();
    if (kUseMockDevice) {
      _startMockDevice();
    } else {
      _initPermissionsAndScan();
    }
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    _scanSubscription?.cancel();
    _mockCameraTimer?.cancel();
    FlutterBluePlus.stopScan();
    _disconnectDeviceSilently();
    _writeController.dispose();
    super.dispose();
  }

  //Get Frame
  Future<void> _requestFrame() async {
    if(_isMock) return;
    final c = _cameraChar;
    if(c == null) return;
    if(!(c.properties.write || c.properties.writeWithoutResponse)) return;
    await c.write([0x01], withoutResponse: c.properties.writeWithoutResponse && !c.properties.write,);
  }

  // ---------------------------
  // BASIC HELPERS
  // ---------------------------

  void _addDeviceToList(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  Future<void> _disconnectDeviceSilently() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {
        // ignore disconnect errors
      }
    }
  }

  // ---------------------------
  // PERMISSIONS + SCANNING
  // ---------------------------

  Future<void> _initPermissionsAndScan() async {
    if (_isMock) return; // mock mode: skip BLE

    var status = await Permission.location.status;
    if (status.isDenied) {
      final newStatus = await Permission.location.request();
      if (newStatus.isGranted || newStatus.isLimited) {
        await _startScan();
      }
    } else if (status.isGranted || status.isLimited) {
      await _startScan();
    }

    if (await Permission.location.status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _startScan() async {
    if (_isMock) return;

    _scanSubscription?.cancel();

    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          for (final ScanResult result in results) {
            _addDeviceToList(result.device);
          }
        }
      },
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(_scanSubscription!);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan();

    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    // Add already-connected devices
    for (final device in FlutterBluePlus.connectedDevices) {
      _addDeviceToList(device);
    }
  }

  // ---------------------------------
  // CONNECT / SERVICES / CAMERA / IMU
  // ---------------------------------

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isMock) return;

    FlutterBluePlus.stopScan();

    try {
      await device.connect();
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    } catch (_) {
      // ignore other errors for now
    }

    final services = await device.discoverServices();

    setState(() {
      _connectedDevice = device;
      _services = services;
    });

    await _attachCameraStreamFromServices();
    await _attachIMUStreamFromServices();
  }

  Future<void> _attachIMUStreamFromServices() async {
    _imuSub?.cancel();

    BluetoothCharacteristic? imuChar;

    for (final service in _services) {
      if (service.uuid == kimuServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == kimuCharUuid) {
            imuChar = characteristic;
            break;
          }
        }
      }
      if (imuChar != null) {
        break;
      }
    }

    if (imuChar == null) {
      // No imu characteristic found; just keep the rest of the UI working.
      return;
    }

    _imuSub = imuChar.lastValueStream.listen((value) {
      if (!mounted) return;

      List<double> accel = List.filled(3, 0.0);;
      List<double> gyro = List.filled(3, 0.0);;
      List<double> mag = List.filled(3, 0.0);;

      if (!decodeIMUData(value, accel, gyro, mag)) return;
      
      setState(() {
        // Each notification contains one packet of IMU data
        for (int i  = 0; i < 3; i++) {
          _accelData[i] = accel[i].toStringAsFixed(2);
          _gyroData[i]  = gyro[i].toStringAsFixed(2);
          _magData[i]   = mag[i].toStringAsFixed(2);
        }

      });
    });

    await imuChar.setNotifyValue(true);
  }

  Future<void> _attachCameraStreamFromServices() async {
    _cameraSub?.cancel();

    BluetoothCharacteristic? cameraChar;

    for (final service in _services) {
      if (service.uuid == kCameraServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == kCameraCharUuid) {
            cameraChar = characteristic;
            break;
          }
        }
      }
      if (cameraChar != null) break;
    }

    if (cameraChar == null) {
      // No camera characteristic found; just keep the rest of the UI working.
      return;
    }

    _cameraChar = cameraChar;

    _cameraSub = cameraChar.lastValueStream.listen((value) {
      if (!mounted) return;
      setState(() {
        // Assumes each notification is a complete encoded image (JPEG/PNG)
        _latestFrame = Uint8List.fromList(value);
      });
    });

    await cameraChar.setNotifyValue(true);
  }

  Future<void> _disconnect() async {
    _cameraSub?.cancel();
    _cameraSub = null;
    _imuSub?.cancel();
    _imuSub = null;

    await _disconnectDeviceSilently();

    setState(() {
      _connectedDevice = null;
      _services = [];
      _latestFrame = null;
    });
  }

  // ---------------------------
  // MOCK / FAKE DEVICE
  // ---------------------------

  void _startMockDevice() {
    _isMock = true;
    _mockCameraTimer?.cancel();

    // Fake "connection" to a Portenta H7
    setState(() {
      _connectedDevice = null;
      _services = [];
      widget.devicesList.clear();
      _latestFrame = null;
    });

    // Fake camera feed: periodically change the frame bytes.
    _mockCameraTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_isMock) {
        timer.cancel();
        return;
      }
      // This is just random-ish data; in a real mock you'd swap between a few
      // known images or patterns.
      final randomBytes = Uint8List.fromList(
        List<int>.generate(2000, (i) => (i * timer.tick) % 255),
      );
      setState(() {
        _latestFrame = randomBytes;
      });
    });
  }

  // ---------------------------
  // UI BUILDERS
  // ---------------------------

  ListView _buildListViewOfDevices() {
    final List<Widget> containers = <Widget>[];

    for (BluetoothDevice device in widget.devicesList) {
      if (!device.platformName.isEmpty) {
        containers.add(
          SizedBox(
            height: 60,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        device.advName.isEmpty
                            ? (device.platformName.isEmpty
                                ? '(unknown device)'
                                : device.platformName)
                            : device.advName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        device.remoteId.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  child: const Text(
                    'Connect',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () => _connectToDevice(device),
                ),
              ],
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
                    widget.readValues[characteristic.uuid] = value;
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

    // WRITE
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('WRITE', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Write"),
                      content: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _writeController,
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text("Send"),
                          onPressed: () {
                            final text = _writeController.value.text;
                            characteristic.write(utf8.encode(text));
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                );
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
                    widget.readValues[characteristic.uuid] = value;
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

  ListView _buildConnectDeviceView() {
    final List<Widget> containers = <Widget>[];

    for (BluetoothService service in _services) {
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
                        'Value: ${widget.readValues[characteristic.uuid]}',
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

  ListView _buildView() {
    if (_isMock) {
      // In mock mode we just show a placeholder list / message
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Mock device mode enabled.\n'
            'No real BLE devices are being scanned.\n'
            'Camera feed above is driven by fake data.',
          ),
        ],
      );
    }

    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }

    return _buildListViewOfDevices();
  }

  Widget _buildCameraView() {
    if (_latestFrame != null) {
      // Attempt to show bytes as an image. If the bytes are not a valid image
      // this will throw – in that case you’ll need to decode differently.
      return Image.memory(
        _latestFrame!,
        fit: BoxFit.cover,
      );
    }

    if (_isMock) {
      return const Center(
        child: Text(
          'Mock camera feed.\nBytes are being generated in software.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_connectedDevice == null) {
      return const Center(
        child: Text(
          'Connect to your Arduino Portenta H7 to see the camera feed.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return const Center(
      child: Text(
        'Connected.\nWaiting for camera data notifications...',
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------------------------
  // MAIN BUILD
  // ---------------------------

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.lightGreen,
        appBar: AppBar(
          backgroundColor: Colors.lightGreen,
          title: Text(widget.title),
          centerTitle: true,
          actions: [
            if (!_isMock && _connectedDevice != null)
              IconButton(
                icon: const Icon(Icons.bluetooth_disabled),
                onPressed: _disconnect,
              ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    _isMock ? Icons.developer_mode : Icons.bluetooth,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isMock
                          ? 'Mode: Mock device (development)'
                          : 'Mode: Real BLE (Portenta H7)',
                          textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // CAMERA FEED AREA
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildCameraView(),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // -------------------------------
            // --- NEW IMU CARD BELOW CAM ---
            // -------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: _requestFrame,
                        child: const Text("Scan Green"),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "IMU Data",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Accel: (x: ${_accelData[0]}, y: ${_accelData[1]}, z: ${_accelData[2]})",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Gyro:  (x: ${_gyroData[0]}, y: ${_gyroData[1]}, z: ${_gyroData[2]})",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mag:   (x: ${_magData[0]}, y: ${_magData[1]}, z: ${_magData[2]})",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // CONTROL BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isMock)
                  ElevatedButton(
                    onPressed: _startScan,
                    child: const Text('Scan for devices'),
                  )
                else
                  ElevatedButton(
                    onPressed: _startMockDevice,
                    child: const Text('Restart mock device'),
                  ),
                const SizedBox(width: 16),
                if (!_isMock && _connectedDevice != null)
                  TextButton(
                    onPressed: _disconnect,
                    child: const Text('Disconnect'),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // DEVICE / SERVICES VIEW
            Expanded(
              child: _buildView(),
            ),
          ],
        ),
      );
}