import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'view/sos_view.dart';

const platform = MethodChannel('com.example.call/audio');

class SOSPage extends StatelessWidget {
  const SOSPage({super.key});

  Future<Map<String, String>> _fetchEmergencyInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user found');

    final userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final phone = userData.data()?['emergencyPhone'] ?? '';
    final address = userData.data()?['address'] ?? '';

    return {'phone': phone, 'address': address};
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _makePhoneCallDirect() async {
    try {
      final info = await _fetchEmergencyInfo();
      final phone = info['phone'] ?? '';
      if (phone.isEmpty) return;

      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
        if (!status.isGranted) return;
      }

      await platform.invokeMethod('makeDirectCall', phone);
    } catch (e) {
      print('Error making call: $e');
    }
  }

  Future<void> _sendSmsDirect(BuildContext context) async {
    try {
      final info = await _fetchEmergencyInfo();
      final phone = info['phone'] ?? '';
      final address = info['address'] ?? '';
      if (phone.isEmpty) return;

      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
        if (!status.isGranted) return;
      }

      String message = '';
      final position = await _getCurrentLocation();
      if (position != null) {
        message =
            "Emergency! My location: https://maps.google.com/?q=${position.latitude},${position.longitude}";
      } else if (address.isNotEmpty) {
        message = "Emergency! My address: $address";
      } else {
        message = "Emergency! No location available.";
      }

      await platform.invokeMethod('sendSMS', {'phone': phone, 'message': message});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS sent successfully!'),
          backgroundColor: Color.fromARGB(255, 231, 186, 246),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error sending SMS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send SMS.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startEmergencyProcedure(BuildContext context) async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('emergencyalaram.mp3'));

      bool cancelled = false;
      int countdown = 5;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              Future.delayed(const Duration(seconds: 1), () {
                if (countdown > 0 && !cancelled) {
                  setState(() => countdown--);
                } else if (countdown == 0 && !cancelled) {
                  Navigator.of(context).pop();
                  _makePhoneCallDirect();
                  player.stop();
                }
              });

              return AlertDialog(
                title: Text('Emergency Call in $countdown seconds'),
                content: const Text('Press Cancel to stop.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      cancelled = true;
                      player.stop();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error starting emergency procedure: $e');
      player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.white : Colors.black);
    return SOSView(
      isDarkMode: isDarkMode,
      iconColor: iconColor,
      onStartCall: () => _startEmergencyProcedure(context),
      onSendSms: () => _sendSmsDirect(context),
    );
  }
}
