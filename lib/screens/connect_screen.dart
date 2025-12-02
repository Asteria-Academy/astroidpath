import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../router/app_router.dart';
import '../services/sound_service.dart';
import '../l10n/app_localizations.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final BleService _bleService = BleService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    SoundService.instance.ensurePlaying();
    _bleService.addListener(_onBleServiceChanged);
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleServiceChanged);
    _bleService.stopScan();
    super.dispose();
  }

  void _onBleServiceChanged() {
    if (mounted) setState(() {});
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    await for (final results in _bleService.startScan()) {
      setState(() {
        _scanResults = results;
      });
    }

    setState(() {
      _isScanning = false;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    await _bleService.stopScan();

    // Navigate to connecting screen
    final success = await Navigator.pushNamed(
      context,
      AppRoutes.connecting,
      arguments: device,
    );

    if (mounted && success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).connectSuccess(device.platformName),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && success == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).connectFail),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1464), Color(0xFF0a0a2e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(l10n),

              // Connection Status
              _buildConnectionStatus(l10n),

              // Scan Results - Revert ke Expanded
              Expanded(
                child: _isScanning || _scanResults.isNotEmpty
                    ? _buildScanResults(l10n)
                    : _buildEmptyState(l10n),
              ),

              // Scan Button
              _buildScanButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              SoundService.instance.playClick();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          Text(
            l10n.connectTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(AppLocalizations l10n) {
    if (!_bleService.isConnected) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x334CAF50), // Green with 20% opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.connectConnected(
                    _bleService.connectedDevice?.platformName ??
                        l10n.connectUnknownDevice,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_bleService.batteryLevel >= 0)
                  Text(
                    l10n.connectBattery(_bleService.batteryLevel),
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF), // White with 70% opacity
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              SoundService.instance.playClick();
              _bleService.disconnect();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanResults(AppLocalizations l10n) {
    // Filter untuk hanya tampilkan devices dengan nama
    final List<ScanResult> filteredResults = _scanResults
        .where((result) => result.device.platformName.isNotEmpty)
        .toList();

    // Sort: Prioritize "AstroidRobot-Beta" first, then by signal strength
    filteredResults.sort((a, b) {
      // Priority #1: AstroidRobot-Beta always on top
      final aIsAstroid = a.device.platformName == "AstroidRobot-Beta";
      final bIsAstroid = b.device.platformName == "AstroidRobot-Beta";
      if (aIsAstroid && !bIsAstroid) return -1;
      if (!aIsAstroid && bIsAstroid) return 1;

      // Priority #2: Sort by signal strength (stronger signal first)
      return b.rssi.compareTo(a.rssi);
    });

    if (filteredResults.isEmpty && !_isScanning) {
      return Center(
        child: Text(
          l10n.connectNoDevices,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final result = filteredResults[index];
        final device = result.device;
        final rssi = result.rssi;
        final isAstroid = device.platformName == "AstroidRobot-Beta";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isAstroid
                ? const Color(0x331A3D6F) // Highlight Astroid robot
                : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAstroid
                  ? const Color(0xFFFFD700) // Gold border for Astroid
                  : device.platformName.contains('Astroid')
                  ? Colors.cyan
                  : Colors.white24,
              width: isAstroid ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              isAstroid ? Icons.smart_toy : Icons.bluetooth,
              color: isAstroid
                  ? const Color(0xFFFFD700)
                  : device.platformName.contains('Astroid')
                  ? Colors.cyan
                  : Colors.white70,
            ),
            title: Text(
              device.platformName.isEmpty
                  ? l10n.connectUnknownDevice
                  : device.platformName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isAstroid ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              device.remoteId.toString(),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rssi dBm',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Icon(
                  _getSignalIcon(rssi),
                  color: _getSignalColor(rssi),
                  size: 20,
                ),
              ],
            ),
            onTap: () {
              SoundService.instance.playClick();
              _connectToDevice(device);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bluetooth_searching,
            size: 80,
            color: Color(0x4DFFFFFF), // White with 30% opacity
          ),
          const SizedBox(height: 20),
          Text(
            l10n.connectNoDevices,
            style: const TextStyle(
              color: Color(0xB3FFFFFF), // White with 70% opacity
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.connectHint,
            style: const TextStyle(
              color: Color(0x80FFFFFF), // White with 50% opacity
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20), // Revert ke padding semula
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isScanning
              ? null
              : () {
                  SoundService.instance.playClick();
                  _startScan();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            disabledBackgroundColor: const Color(0x8000BCD4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isScanning
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.connectScanning),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Text(l10n.connectScan),
                  ],
                ),
        ),
      ),
    );
  }

  IconData _getSignalIcon(int rssi) {
    if (rssi >= -60) return Icons.signal_cellular_4_bar;
    if (rssi >= -70) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }
}
