import 'package:flutter/material.dart';
import 'package:perfect_putt/pages/bluetooth_page.dart';
import 'instructions_page.dart';
import 'data_collection_page.dart';
import 'autohit_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfect Putt"),
      ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InstructionsPage()),
                  );
                },
                child: const Text("Start Putting Session"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AutohitPage()),
                  );
                },
                child: const Text("Use Auto-Hit"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BluetoothPage()),
                  );
                },
                child: const Text("Connect to Bluetooth"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DataCollectionPage(title: "Data Collection"),
                    ),
                  );
                },
                child: const Text("Data Collection Mode"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}