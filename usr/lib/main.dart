import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.car_repair, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'ELM327 Scanner',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _authenticate,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(_isLogin ? 'Login' : 'Register'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Don\'t have an account? Register'
                                : 'Already have an account? Login',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _authenticate() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate authentication (replace with real auth later)
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', _emailController.text);

    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ConnectingScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to ELM327 Scanner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
                title: const Text('Device Status'),
                subtitle: const Text('Not Connected'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to connecting screen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConnectingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  Card(
                    child: ListTile(
                      title: Text('RPM'),
                      subtitle: Text('Last reading: 2500 RPM'),
                      trailing: Text('2 min ago'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text('Engine Temp'),
                      subtitle: Text('Last reading: 85°C'),
                      trailing: Text('5 min ago'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text('DTC Codes'),
                      subtitle: Text('No codes detected'),
                      trailing: Text('10 min ago'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectingScreen extends StatefulWidget {
  const ConnectingScreen({super.key});

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> {
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription? _readSubscription;

  String _realTimeData = "N/A";
  String _dtcData = "N/A";
  bool _isScanning = false;
  bool _isConnected = false;
  String _errorMessage = "";

  // Server URL to send data to
  final String _serverUrl = "YOUR_SERVER_URL_HERE"; // TODO: Replace with your server URL

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  @override
  void dispose() {
    _readSubscription?.cancel();
    super.dispose();
  }

  void _checkBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        setState(() {
          _errorMessage = "";
        });
      } else {
        setState(() {
          _errorMessage = "Bluetooth is turned off. Please enable Bluetooth to use this app.";
        });
      }
    });
  }

  void _startScan() {
    if (_errorMessage.isNotEmpty) return;
    setState(() {
      _isScanning = true;
      _scanResults = [];
      _errorMessage = "";
    });
    try {
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
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = "Error starting scan: $e";
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _errorMessage = "";
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
    } catch (e) {
      setState(() {
        _errorMessage = "Error connecting to device: $e";
      });
    }
  }

  Future<void> _disconnectFromDevice() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        setState(() {
          _connectedDevice = null;
          _isConnected = false;
          _realTimeData = "N/A";
          _dtcData = "N/A";
          _errorMessage = "";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error disconnecting: $e";
      });
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_writeCharacteristic != null) {
      try {
        List<int> bytes = utf8.encode('$command\r\n');
        await _writeCharacteristic!.write(bytes);
      } catch (e) {
        setState(() {
          _errorMessage = "Error sending command: $e";
        });
      }
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
        title: const Text('Connect to ELM327'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnectFromDevice,
            )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startScan,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_isConnected) {
      return _buildConnectedView();
    } else {
      return _buildDeviceListView();
    }
  }

  Widget _buildDeviceListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Scan for ELM327 Devices',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure your ELM327 device is powered on and in pairing mode.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isScanning) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final result = _scanResults[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text(result.device.platformName),
                  subtitle: Text(result.device.remoteId.toString()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _connectToDevice(result.device),
                ),
              );
            },
          ),
        ),
        if (_scanResults.isEmpty && !_isScanning)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "No devices found. Make sure your ELM327 device is powered on and in pairing mode.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
      ],
    );
  }

  Widget _buildConnectedView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
              title: Text("Connected to: ${_connectedDevice?.platformName ?? 'Unknown'}"),
              subtitle: const Text('Device is ready'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Real-time Diagnostics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getRealTimeData,
                  icon: const Icon(Icons.speed),
                  label: const Text("Get RPM"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getDTCs,
                  icon: const Icon(Icons.warning),
                  label: const Text("Get DTCs"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latest Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('RPM: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_realTimeData),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('DTCs: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(child: Text(_dtcData)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController(text: 'YOUR_SERVER_URL_HERE');
  bool _autoSendData = false;
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrlController.text = prefs.getString('serverUrl') ?? 'YOUR_SERVER_URL_HERE';
      _autoSendData = prefs.getBool('autoSendData') ?? false;
      _selectedTheme = prefs.getString('theme') ?? 'Light';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', _serverUrlController.text);
    await prefs.setBool('autoSendData', _autoSendData);
    await prefs.setString('theme', _selectedTheme);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Server Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _serverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://your-server.com/api/data',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              title: const Text('Auto-send Data'),
              subtitle: const Text('Automatically send data to server when received'),
              value: _autoSendData,
              onChanged: (value) {
                setState(() {
                  _autoSendData = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              title: const Text('Theme'),
              subtitle: Text(_selectedTheme),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Select Theme'),
                    children: ['Light', 'Dark', 'System'].map((theme) {
                      return SimpleDialogOption(
                        onPressed: () {
                          setState(() {
                            _selectedTheme = theme;
                          });
                          Navigator.pop(context);
                        },
                        child: Text(theme),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ELM327 Bluetooth Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Version 1.0.0'),
                  SizedBox(height: 4),
                  Text('Connect to ELM327 diagnostic equipment via Bluetooth and send real-time data to a server.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
