import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    hide BluetoothConnectionState;
import '../services/ble_service.dart';

class ConnectingScreen extends StatefulWidget {
  const ConnectingScreen({super.key, required this.device});

  final BluetoothDevice device;

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> {
  final BleService _bleService = BleService();
  bool _isNavigationScheduled = false;

  @override
  void initState() {
    super.initState();
    _bleService.addListener(_onBleServiceChanged);
    _bleService.connectToDevice(widget.device);
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleServiceChanged);
    super.dispose();
  }

  void _onBleServiceChanged() {
    if (!mounted) return;

    if (_bleService.connectionState == BluetoothConnectionState.connected &&
        !_isNavigationScheduled) {
      _isNavigationScheduled = true;
      // Auto-navigate back after successful connection
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true = success
        }
      });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button during connection
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1433),
        body: Stack(
          children: [
            // Galaxy background
            Positioned.fill(
              child: Image.asset('assets/splash/bg.png', fit: BoxFit.cover),
            ),

            // Content
            Center(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_bleService.connectionState) {
      case BluetoothConnectionState.connected:
        return _StatusIndicator(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF4CAF50),
          glowColor: const Color(0xFF81C784),
          message: "Successfully Connected!",
          subtitle: "Connected to ${widget.device.platformName}",
        );

      case BluetoothConnectionState.connectionFailed:
        return _StatusIndicator(
          icon: Icons.error_rounded,
          iconColor: const Color(0xFFF44336),
          glowColor: const Color(0xFFEF5350),
          message: "Connection Failed",
          subtitle: "Could not connect to robot",
          buttonText: "Go Back",
          onButtonPressed: () => Navigator.of(context).pop(false),
        );

      case BluetoothConnectionState.connecting:
      default:
        return _StatusIndicator(
          icon: null, // Will show loading spinner
          iconColor: const Color(0xFF00BCD4),
          glowColor: const Color(0xFF4DD0E1),
          message: "Connecting...",
          subtitle: "Establishing connection to ${widget.device.platformName}",
          buttonText: "Cancel",
          onButtonPressed: () {
            _bleService.disconnect();
            Navigator.of(context).pop(false);
          },
        );
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.icon,
    required this.iconColor,
    required this.glowColor,
    required this.message,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  final IconData? icon;
  final Color iconColor;
  final Color glowColor;
  final String message;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0x66122A4D), Color(0x660F1D3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color.fromARGB(102, 115, 240, 255),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(64, glowColor.red, glowColor.green, glowColor.blue), // ignore: deprecated_member_use
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon or Loading Spinner
          if (icon != null)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(128, glowColor.red, glowColor.green, glowColor.blue), // ignore: deprecated_member_use,
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, size: 96, color: iconColor),
            )
          else
            SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),

          const SizedBox(height: 32),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color.fromARGB(179, 255, 255, 255),
              ),
            ),
          ],

          // Button
          if (buttonText != null) ...[
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF41D8FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
                shadowColor: const Color.fromARGB(128, 65, 216, 255),
              ),
              child: Text(
                buttonText!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
