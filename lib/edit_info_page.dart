import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditInfoPage extends StatefulWidget {
  const EditInfoPage({Key? key}) : super(key: key);

  @override
  _EditInfoPageState createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  late final StreamSubscription<User?> _authSubscription;
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _auth.setLanguageCode("en");
    _loadUserData();
    _setupAuthListener();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && mounted) {
          setState(() {
            _addressController.text = userData.data()?['address'] ?? '';
            _emergencyPhoneController.text =
                userData.data()?['emergencyPhone'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error loading user data: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription.cancel();
    _addressController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {});
  }

  Future<void> _updateAddress() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied.');
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        throw Exception('Unable to get address from location.');
      }

      Placemark place = placemarks.first;
      String address =
          '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

      await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
        'address': address,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _addressController.text = address;
        _showSnackbar('Address updated successfully.');
      }
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}');
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateEmergencyNumber() async {
    if (_emergencyPhoneController.text.trim().isEmpty) {
      _showSnackbar('Please enter the emergency phone number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
        'emergencyPhone': _emergencyPhoneController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Emergency phone number updated successfully.');
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}');
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message) {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final cardColor =
        isDarkMode ? Colors.grey[800]! : Colors.white.withOpacity(0.8);
    final iconColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [Colors.black, Colors.grey[900]!, Colors.black87]
                  : [
                    Color.fromARGB(255, 236, 184, 201),
                    Colors.white,
                    Color.fromARGB(255, 212, 184, 243),
                  ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Edit Info', style: TextStyle(color: iconColor)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(
                _addressController,
                'Home Address',
                Icons.home,
                TextInputType.multiline,
                cardColor,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              _buildButton('Update Address', _updateAddress),

              const SizedBox(height: 30),
              _buildTextField(
                _emergencyPhoneController,
                'Emergency Phone Number',
                Icons.phone,
                TextInputType.phone,
                cardColor,
              ),
              const SizedBox(height: 20),
              _buildButton('Update Emergency Number', _updateEmergencyNumber),

              const SizedBox(height: 32),
              Divider(color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType type,
    Color fillColor, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        enabled: !_isLoading,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child:
          _isLoading
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Text(text, style: TextStyle(fontSize: 16)),
    );
  }
}
