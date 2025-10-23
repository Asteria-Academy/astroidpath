import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/robot_command.dart';

/// Enum untuk state koneksi Bluetooth
enum BluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  connectionFailed,
}

/// Service untuk mengelola koneksi BLE dengan robot
class BleService extends ChangeNotifier {
  // Singleton pattern
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // Nordic UART Service UUIDs (sesuai dengan firmware)
  static const String _serviceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String _rxCharUUID =
      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // Write
  static const String _txCharUUID =
      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Notify

  // State variables
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _deviceStateSubscription;
  StreamSubscription? _notificationSubscription;

  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  int _batteryLevel = -1;
  String _lastReceivedData = '';
  String? _lastConnectionError;

  // Getters
  BluetoothConnectionState get connectionState => _connectionState;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  int get batteryLevel => _batteryLevel;
  String get lastReceivedData => _lastReceivedData;
  String? get lastConnectionError => _lastConnectionError;

  // Backward compatibility getters
  bool get isScanning => _connectionState == BluetoothConnectionState.scanning;
  bool get isConnected =>
      _connectionState == BluetoothConnectionState.connected;
  String get connectionStatus {
    switch (_connectionState) {
      case BluetoothConnectionState.disconnected:
        return 'Disconnected';
      case BluetoothConnectionState.scanning:
        return 'Scanning...';
      case BluetoothConnectionState.connecting:
        return 'Connecting...';
      case BluetoothConnectionState.connected:
        return 'Connected to ${_connectedDevice?.platformName ?? "Device"}';
      case BluetoothConnectionState.connectionFailed:
        return 'Connection Failed';
    }
  }

  Future<bool> requestPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      debugPrint('✅ BLE Permissions granted');
      return true;
    } else {
      debugPrint('❌ BLE Permissions denied');
      return false;
    }
  }

  Future<bool> isBluetoothOn() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('❌ Error checking BT state: $e');
      return false;
    }
  }

  Stream<List<ScanResult>> startScan() async* {
    if (_connectionState == BluetoothConnectionState.scanning) {
      debugPrint('⚠️ Already scanning');
      return;
    }

    // Check permissions
    if (!await requestPermissions()) {
      debugPrint('❌ Permissions not granted');
      return;
    }

    // Check BT is on
    if (!await isBluetoothOn()) {
      debugPrint('❌ Bluetooth is OFF');
      return;
    }

    _updateConnectionState(BluetoothConnectionState.scanning);

    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      // Yield scan results
      await for (final results in FlutterBluePlus.scanResults) {
        yield results;
      }
    } catch (e) {
      debugPrint('❌ Scan error: $e');
    } finally {
      _updateConnectionState(BluetoothConnectionState.disconnected);
      await FlutterBluePlus.stopScan();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    if (_connectionState == BluetoothConnectionState.scanning) {
      await FlutterBluePlus.stopScan();
      _updateConnectionState(BluetoothConnectionState.disconnected);
    }
  }

  /// Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    _lastConnectionError = null;

    if (isConnected) {
      if (device.remoteId == _connectedDevice?.remoteId) {
        return true;
      }
      await disconnect();
    }

    _updateConnectionState(BluetoothConnectionState.connecting);

    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
        license: License.free,
      );

      _connectedDevice = device;

      await Future.delayed(const Duration(milliseconds: 500));

      List<BluetoothService> services = await device.discoverServices().timeout(
        const Duration(seconds: 20),
      );

      BluetoothService? uartService;
      for (var service in services) {
        if (service.uuid.toString().toUpperCase() ==
            _serviceUUID.toUpperCase()) {
          uartService = service;
          break;
        }
      }

      if (uartService == null) {
        _lastConnectionError =
            "Could not find required UART service/characteristics. Check if device firmware is correct.";
        await disconnect();
        return false;
      }

      // Find RX and TX characteristics
      for (var characteristic in uartService.characteristics) {
        String charUuid = characteristic.uuid.toString().toUpperCase();

        if (charUuid == _rxCharUUID.toUpperCase()) {
          _rxCharacteristic = characteristic;
          debugPrint('✅ Found RX Characteristic');
        } else if (charUuid == _txCharUUID.toUpperCase()) {
          _txCharacteristic = characteristic;
          debugPrint('✅ Found TX Characteristic');

          // Subscribe to notifications
          await characteristic.setNotifyValue(true);
          _notificationSubscription = characteristic.lastValueStream.listen(
            _handleReceivedData,
            onError: (error) => debugPrint('❌ Notification error: $error'),
          );
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        _lastConnectionError =
            "Could not find required UART service/characteristics. Check if device firmware is correct.";
        await disconnect();
        return false;
      }

      _deviceStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint("Device disconnected unexpectedly.");
          _handleDisconnection();
        }
      });

      _updateConnectionState(BluetoothConnectionState.connected);
      debugPrint('✅ Successfully connected to ${device.platformName}');

      await sendCommand(RobotCommand.getBatteryStatus());

      return true;
    } catch (e) {
      debugPrint('❌ Connection error: $e');

      // Parse error for user-friendly message
      String errorMsg = e.toString();
      if (errorMsg.contains('timeout') ||
          errorMsg.contains('TimeoutException')) {
        _lastConnectionError =
            "Connection timeout. Device may be out of range or busy.";
      } else if (errorMsg.contains('connect')) {
        _lastConnectionError = "Failed to establish connection. Try again.";
      } else if (errorMsg.contains('discover') ||
          errorMsg.contains('service')) {
        _lastConnectionError =
            "Service discovery failed. Device may be incompatible.";
      } else {
        _lastConnectionError =
            "Connection error: ${errorMsg.length > 100 ? '${errorMsg.substring(0, 100)}...' : errorMsg}";
      }

      try {
        if (_connectedDevice != null) {
          await _connectedDevice!.disconnect();
        }
      } catch (disconnectError) {
        debugPrint("Error during cleanup disconnect: $disconnectError");
      }

      _updateConnectionState(BluetoothConnectionState.connectionFailed);
      _handleDisconnection();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _notificationSubscription?.cancel();
      await _deviceStateSubscription?.cancel();
      await _connectedDevice?.disconnect();

      _handleDisconnection();
      debugPrint('✅ Disconnected');
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    }
  }

  Future<bool> sendCommand(RobotCommand command) async {
    if (_connectionState != BluetoothConnectionState.connected ||
        _rxCharacteristic == null) {
      debugPrint('❌ Not connected or RX characteristic not found');
      return false;
    }

    try {
      String jsonString = command.toJson();
      List<int> bytes = utf8.encode(jsonString);

      debugPrint('📤 Sending: $jsonString');
      await _rxCharacteristic!.write(bytes, withoutResponse: false);

      return true;
    } catch (e) {
      debugPrint('❌ Send error: $e');
      return false;
    }
  }

  void _handleReceivedData(List<int> data) {
    try {
      String received = utf8.decode(data);
      _lastReceivedData = received;
      debugPrint('📥 Received: $received');

      final json = jsonDecode(received);

      if (json['status'] == 'BATTERY') {
        _batteryLevel = json['level'] ?? -1;
        debugPrint('🔋 Battery: $_batteryLevel%');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Parse error: $e');
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _batteryLevel = -1;
    _updateConnectionState(BluetoothConnectionState.disconnected);
  }

  void _updateConnectionState(BluetoothConnectionState newState) {
    _connectionState = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
