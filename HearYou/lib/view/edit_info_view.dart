import 'package:flutter/material.dart';

class EditInfoView extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final bool isLoading;
  final VoidCallback onUpdateAddress;
  final VoidCallback onUpdatePhone;

  const EditInfoView({
    super.key,
    required this.isDarkMode,
    required this.addressController,
    required this.phoneController,
    required this.isLoading,
    required this.onUpdateAddress,
    required this.onUpdatePhone,
  });

  @override
  Widget build(BuildContext context) {
    final inputFillColor = isDarkMode ? Colors.black45 : Colors.white;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text('Edit Info', style: TextStyle(color: iconColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: iconColor), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set your default location and phone number to be used in case of emergency.', style: TextStyle(color: iconColor.withOpacity(0.8), fontSize: 14)),
            const SizedBox(height: 16),
            _buildTextField(addressController, 'Home Address', Icons.home, TextInputType.multiline, inputFillColor, isDarkMode, maxLines: 2, enabled: !isLoading),
            const SizedBox(height: 20),
            _buildPrimaryButton('Update Address', onUpdateAddress, isDarkMode, isLoading),
            const SizedBox(height: 30),
            _buildTextField(phoneController, 'Emergency Phone Number', Icons.phone, TextInputType.phone, inputFillColor, isDarkMode, enabled: !isLoading),
            const SizedBox(height: 20),
            _buildPrimaryButton('Update Emergency Number', onUpdatePhone, isDarkMode, isLoading),
            const SizedBox(height: 32),
            Divider(color: isDarkMode ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, TextInputType type, Color fillColor, bool isDarkMode, {int maxLines = 1, required bool enabled}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.white : null),
        hintText: label,
        hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black, width: 1.2)),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed, bool isDarkMode, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}


