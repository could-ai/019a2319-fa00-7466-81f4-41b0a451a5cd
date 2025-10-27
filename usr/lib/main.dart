import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELM327 Bluetooth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription? _readSubscription;

  String _realTimeData = "N/A";
  String _dtcData = "N/A";
  bool _isScanning = false;
  bool _isConnected = false;

  // Server URL to send data to
  final String _serverUrl = "YOUR_SERVER_URL_HERE"; // TODO: Replace with your server URL

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _readSubscription?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList();
      });
    });
    Future.delayed(const Duration(seconds: 5), () {
      FlutterBluePlus.stopScan();
      setState(() {
        _isScanning = false;
      });
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      _connectedDevice = device;
      _isConnected = true;
    });

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          _writeCharacteristic = characteristic;
        }
        if (characteristic.properties.notify || characteristic.properties.read) {
          _readCharacteristic = characteristic;
        }
      }
    }

    if (_readCharacteristic != null) {
      await _readCharacteristic!.setNotifyValue(true);
      _readSubscription = _readCharacteristic!.value.listen((value) {
        String response = utf8.decode(value);
        // Process incoming data here
        print("Received: $response");
        // For simplicity, we'll just display raw data.
        // In a real app, you'd parse this based on the command sent.
        if (response.contains("41 0C")) { // RPM response
           setState(() {
             _realTimeData = response;
           });
        } else if (response.contains("43")) { // DTC response
           setState(() {
             _dtcData = response;
           });
        }
        _sendDataToServer("raw_response", response);
      });
    }
  }

  Future<void> _disconnectFromDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _isConnected = false;
        _realTimeData = "N/A";
        _dtcData = "N/A";
      });
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_writeCharacteristic != null) {
      List<int> bytes = utf8.encode('$command\r\n');
      await _writeCharacteristic!.write(bytes);
    }
  }

  Future<void> _getRealTimeData() async {
    // Example: Request Engine RPM (PID 0C)
    await _sendCommand("010C");
  }

  Future<void> _getDTCs() async {
    // Request Diagnostic Trouble Codes
    await _sendCommand("03");
  }

  Future<void> _sendDataToServer(String dataType, String data) async {
    if (_serverUrl == "YOUR_SERVER_URL_HERE") {
      print("Server URL not set. Cannot send data.");
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'dataType': dataType,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        print("Data sent to server successfully.");
      } else {
        print("Failed to send data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending data to server: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELM327 OBD2 Scanner'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnectFromDevice,
            )
          else if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isConnected) {
      return _buildConnectedView();
    } else {
      return _buildDeviceListView();
    }
  }

  Widget _buildDeviceListView() {
    return Column(
      children: [
        if (_isScanning) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final result = _scanResults[index];
              return ListTile(
                title: Text(result.device.platformName),
                subtitle: Text(result.device.remoteId.toString()),
                onTap: () => _connectToDevice(result.device),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Connected to: ${_connectedDevice?.platformName ?? 'Unknown'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getRealTimeData,
            child: const Text("Get Real-time Data (RPM)"),
          ),
          const SizedBox(height: 10),
          Text("Real-time Data: $_realTimeData"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getDTCs,
            child: const Text("Get Diagnostic Trouble Codes"),
          ),
          const SizedBox(height: 10),
          Text("DTCs: $_dtcData"),
        ],
      ),
    );
  }
}
