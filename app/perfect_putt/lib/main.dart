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

/// Model for ML analysis results - provides putting guidance
class PuttAnalysisResult {
  final double powerPercentage; // How hard to hit (0-100%)
  final double angleFromHole;   // Angle relative to hole in degrees (-180 to 180)
  final double distanceToHole;  // Estimated distance in feet/meters
  final double greenSlope;      // Slope percentage
  final String breakDirection;  // "left", "right", "straight"
  final List<String> tips;      // Additional tips
  final Uint8List? analyzedFrame;
  
  PuttAnalysisResult({
    required this.powerPercentage,
    required this.angleFromHole,
    required this.distanceToHole,
    required this.greenSlope,
    required this.breakDirection,
    required this.tips,
    this.analyzedFrame,
  });
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

  // Navigate to capture instruction screen
  void _startGreenScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaptureInstructionScreen(
          onCapture: _captureFrameAndAnalyze,
          isMock: _isMock,
        ),
      ),
    );
  }

  // Capture frame and start analysis
  Future<void> _captureFrameAndAnalyze() async {
    /*/ Request frame if not in mock mode
    if(!_isMock) {
      final c = _cameraChar;
      if(c == null) return;
      if(!(c.properties.write || c.properties.writeWithoutResponse)) return;
      await c.write([0x01], withoutResponse: c.properties.writeWithoutResponse && !c.properties.write,);
      
      // Wait a moment for the frame to arrive
      await Future.delayed(const Duration(milliseconds: 500));
    }*/
    
    // Return the captured data
    return;
  }


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
        backgroundColor: Colors.lightGreen,
        appBar: AppBar(
          backgroundColor: Colors.lightGreen,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        "Swing Data",
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
              onPressed: _startGreenScan,
              child: const Text("Start Green Scan"),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _exportTrainingData,
              child: const Text("Export Training Data"),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _ble.startScan((devices) {
                  setState(() {
                    widget.devicesList..clear()..addAll(devices);
                  });
                });
              },
              child: const Text("Scan for Devices"),
            ),

            /*/ CONTROL BUTTONS
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
            ),*/

            const SizedBox(height: 8),

            // DEVICE / SERVICES VIEW
            Expanded(
              child: _buildView(),
            ),
          ],
        ),
      );
}

class CaptureInstructionScreen extends StatefulWidget {
  final Future<void> Function() onCapture;
  final bool isMock;

  const CaptureInstructionScreen({
    Key? key,
    required this.onCapture,
    required this.isMock,
  }) : super(key: key);

  @override
  State<CaptureInstructionScreen> createState() => _CaptureInstructionScreenState();
}

class _CaptureInstructionScreenState extends State<CaptureInstructionScreen> {
  bool _isCapturing = false;

  Future<void> _handleCapture() async {
    setState(() {
      _isCapturing = true;
    });

    //call the capture function
    await widget.onCapture();

    if (!mounted) return;

    //navigate to loading screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoadingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: const Text('Position Camera'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: Colors.lightGreen,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Instructions
              const Text(
                'Hold Putter Still',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _InstructionItem(
                        icon: Icons.straighten,
                        text: 'Hold the putter upright and steady',
                      ),
                      const SizedBox(height: 16),
                      _InstructionItem(
                        icon: Icons.visibility,
                        text: 'Point camera at the green and hole',
                      ),
                      const SizedBox(height: 16),
                      _InstructionItem(
                        icon: Icons.center_focus_strong,
                        text: 'Center the hole in the camera view',
                      ),
                      const SizedBox(height: 16),
                      _InstructionItem(
                        icon: Icons.pan_tool,
                        text: 'Keep the device completely still',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Capture button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isCapturing ? null : _handleCapture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: _isCapturing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
                          ),
                        )
                      : const Text(
                          'Capture Green',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.lightGreen, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Loading screen - Shows while ML model processes the data


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _runMLAnalysis();
  }

  Future<void> _runMLAnalysis() async {
    //  Replace this with ML model

    
    // simulate
    await Future.delayed(const Duration(seconds: 3));
    
    // fake results
    final mockResults = _generateMockResults();
    
    if (!mounted) return;
    
    // navigate to results screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(result: mockResults),
      ),
    );
  }
  
  PuttAnalysisResult _generateMockResults() {
    // fake data for demo
    return PuttAnalysisResult(
      powerPercentage: 65.0,  
      angleFromHole: -12.5,    
      distanceToHole: 8.5,    
      greenSlope: 2.3,       
      breakDirection: "left",  
      tips: [
        "Use a smooth, controlled stroke at 65% power",
      ],
      analyzedFrame: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 6,
            ),
            const SizedBox(height: 32),
            const Text(
              'Analyzing the green...',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                'Our AI model is calculating the optimal putt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildLoadingSteps(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          _LoadingStep(
            icon: Icons.landscape,
            text: "Mapping green topography",
            delay: 0,
          ),
          const SizedBox(height: 12),
          _LoadingStep(
            icon: Icons.straighten,
            text: "Calculating slope & break",
            delay: 0,
          ),
          const SizedBox(height: 12),
          _LoadingStep(
            icon: Icons.sports_golf,
            text: "Computing optimal trajectory",
            delay: 0,
          ),
        ],
      ),
    );
  }
}

class _LoadingStep extends StatefulWidget {
  final IconData icon;
  final String text;
  final int delay;

  const _LoadingStep({
    required this.icon,
    required this.text,
    required this.delay,
  });

  @override
  State<_LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<_LoadingStep> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    Future.delayed(Duration(milliseconds: widget.delay * 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Row(
        children: [
          Icon(widget.icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Results screen

class ResultsScreen extends StatelessWidget {
  final PuttAnalysisResult result;

  const ResultsScreen({Key? key, required this.result}) : super(key: key);

  String _getAngleDirection() {
    if (result.angleFromHole > 0) {
      return "right of hole";
    } else if (result.angleFromHole < 0) {
      return "left of hole";
    } else {
      return "directly at hole";
    }
  }

  Color _getPowerColor() {
    if (result.powerPercentage < 33) return Colors.green;
    if (result.powerPercentage < 66) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: const Text('Perfect Putt Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Main instruction card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.golf_course,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Putt Instructions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${result.distanceToHole.toStringAsFixed(1)} feet to hole',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // power gauge
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed, color: _getPowerColor(), size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Power',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: result.powerPercentage / 100,
                                minHeight: 30,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getPowerColor(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${result.powerPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getPowerColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.powerPercentage < 33
                            ? 'Gentle tap'
                            : result.powerPercentage < 66
                                ? 'Moderate stroke'
                                : 'Firm hit',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Angle/Direction card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.explore, color: Colors.purple, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Aim Direction',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (result.angleFromHole < 0)
                            const Icon(
                              Icons.arrow_back,
                              size: 40,
                              color: Colors.purple,
                            ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Text(
                                '${result.angleFromHole.abs().toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              Text(
                                _getAngleDirection(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          if (result.angleFromHole > 0)
                            const Icon(
                              Icons.arrow_forward,
                              size: 40,
                              color: Colors.purple,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Green conditions
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.landscape, color: Colors.teal, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Green Conditions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ConditionRow(
                        label: 'Slope',
                        value: '${result.greenSlope.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 8),
                      _ConditionRow(
                        label: 'Break',
                        value: result.breakDirection.toUpperCase(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tips section
              if (result.tips.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.amber, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Pro Tips',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...result.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate back to home and prepare for next scan
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.lightGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement scoring/game completion
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Scored! 🎉'),
                            content: const Text('Great putt! Ready for the next hole?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                child: const Text('Next Hole'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.flag),
                      label: const Text('I Scored'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConditionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}