import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble/ble_communication.dart';
import 'putting_metrics/putting_metrics.dart';

/// Toggle this for dev:
/// true  = use fake/mock device (no real BLE needed)
/// false = use real Arduino Portenta H7 over BLE
const bool kUseMockDevice = false;


/***************************DEBUGGING/TESTING***************************/

void test() {
  final testData1 = PuttingMetrics(
    putterToHoleDist: 8.5,
    holeCenterOffset: 2.1,
    ballToHoleDistX: 6.3,
    ballToHoleDistY: 1.1,
    swingForce: 1.2,
    putterAngle: 1.1,
    followThroughDeg: 85.0,
    successfulShot: false,
  );
  final testData2 = PuttingMetrics(
    putterToHoleDist: 8.5,
    holeCenterOffset: 2.1,
    ballToHoleDistX: 6.3,
    ballToHoleDistY: 1.1,
    swingForce: 1.2,
    putterAngle: 1.1,
    followThroughDeg: 84.0,
    successfulShot: false,
  );
  final testData3 = PuttingMetrics(
    putterToHoleDist: 8.5,
    holeCenterOffset: 2.1,
    ballToHoleDistX: 6.3,
    ballToHoleDistY: 1.1,
    swingForce: 1.2,
    putterAngle: 1.1,
    followThroughDeg: 83.0,
    successfulShot: true,
  );

  final List<PuttingMetrics> testDataTransmission = [testData1, testData2, testData3];
  PuttingMetrics.exportMetrics(testDataTransmission, "Test data");
}

/***************************DEBUGGING/TESTING***************************/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Perfect Putt',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)
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

  late BleCommunication _ble;
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  
  // Camera feed state
  Uint8List? _latestFrame;
  
  // Current input data state
  PuttingMetrics _currMetrics = PuttingMetrics(putterToHoleDist: 0,
                                              holeCenterOffset: 0,
                                              ballToHoleDistX: 0,
                                              ballToHoleDistY: 0,
                                              swingForce: 0,
                                              putterAngle: 0,
                                              followThroughDeg: 0,
                                              successfulShot: false);
  List<int> _tempMetrics = List.filled(28, 0);

  // Storage for all data
  final List<PuttingMetrics> _metricsStorage = [];

  // Mock mode
  bool _isMock = kUseMockDevice;
  Timer? _mockCameraTimer;

  @override
  void initState() {
    super.initState();
    _ble = BleCommunication();
  }

  @override
  void dispose() {
    _ble.disconnect();
    _writeController.dispose();
    super.dispose();
  }

  // ---------------------------
  // BASIC HELPERS
  // ---------------------------

  // ---------------------------
  // TRANSMITTING DATA
  // ---------------------------
  Future<void> _exportTrainingData() async {
    // Send data
    PuttingMetrics.exportMetrics(_metricsStorage, "Test Data");
  }

  // ---------------------------
  // PERMISSIONS + SCANNING
  // ---------------------------

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
      if (device.platformName == "PERFECTPUTT") {
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
                  onPressed: () {
                    _ble.connect(
                      device,
                      onServicesReady: (services) {
                        setState(() {
                          _connectedDevice = device;
                          _services = services;
                        });
                      },
                      onPreSwingReceived: (metricsBytes) {
                        setState(() {
                          _currMetrics.updatePreSwingData(metricsBytes);
                          if (_currMetrics.preSwingUpdated && _currMetrics.postSwingUpdated) {
                            _metricsStorage.add(_currMetrics.copy());
                            _currMetrics.preSwingUpdated = false;
                            _currMetrics.postSwingUpdated = false;
                          }
                        });
                      },
                      onPostSwingReceived: (metricsBytes) {
                        setState(() {
                          _currMetrics.updatePostSwingData(metricsBytes);
                          if (_currMetrics.preSwingUpdated && _currMetrics.postSwingUpdated) {
                            _metricsStorage.add(_currMetrics.copy());
                            _currMetrics.preSwingUpdated = false;
                            _currMetrics.postSwingUpdated = false;
                          }
                        });
                      },
                      onFrameReceived: (frame) {
                        setState(() {
                          _latestFrame = frame;
                        });
                      },
                    );
                  },
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(widget.title),
          centerTitle: true,
          actions: [
            if (!_isMock && _connectedDevice != null)
              IconButton(
                icon: const Icon(Icons.bluetooth_disabled),
                onPressed: () async {
                  await _ble.disconnect();
                  setState(() {
                    _connectedDevice = null;
                    _services = [];
                    _latestFrame = null;
                  });
                },
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
            
            const SizedBox(height: 12),
            
            // ---------------------------------
            // --- Description of Swing Data ---
            // ---------------------------------
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
                        onPressed: () async {
                          final preSwingDataChar = _ble.getPreSwingDataChar();
                          final postSwingDataChar = _ble.getPostSwingDataChar();

                          if (preSwingDataChar == null || postSwingDataChar == null) return;

                          final sub = preSwingDataChar.lastValueStream.listen((value) {
                            setState(() {
                              widget.readValues[preSwingDataChar.uuid] = value;
                            });
                          });
                          final subTwo = postSwingDataChar.lastValueStream.listen((value) {
                            setState(() {
                              widget.readValues[postSwingDataChar.uuid] = value;
                            });
                          });
                          await preSwingDataChar.read();
                          await postSwingDataChar.read();
                          await sub.cancel();
                          await subTwo.cancel();
                        },
                        child: const Text("Collect swing data"),
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
                        "Distance between putter and hole: ${_currMetrics.putterToHoleDist.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Center offset of hole before swing: ${_currMetrics.holeCenterOffset.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Horizontal distance between ball and hole after swing: ${_currMetrics.ballToHoleDistX.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Vertical distance between ball and hole after swing: ${_currMetrics.ballToHoleDistY.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Force of swing: ${_currMetrics.swingForce.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Angle of putter before swing: ${_currMetrics.putterAngle.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Degree of follow through: ${_currMetrics.followThroughDeg.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Was the shot successful? ${_currMetrics.successfulShot ? "Yes!" : "No."}",
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _exportTrainingData,
              child: const Text("Export Training Data"),
            ),

            // CONTROL BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isMock)
                  ElevatedButton(
                    onPressed: () {
                      _ble.startScan((devices) {
                        setState(() {
                          widget.devicesList..clear()..addAll(devices);
                        });
                      });
                    },
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
                    onPressed: () async {
                      await _ble.disconnect();
                      setState(() {
                        _connectedDevice = null;
                        _services = [];
                        _latestFrame = null;
                      });
                    },
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