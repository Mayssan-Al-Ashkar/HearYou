import 'package:flutter/material.dart';

class SOSView extends StatelessWidget {
  final bool isDarkMode;
  final Color iconColor;
  final VoidCallback onStartCall;
  final VoidCallback onSendSms;

  const SOSView({
    super.key,
    required this.isDarkMode,
    required this.iconColor,
    required this.onStartCall,
    required this.onSendSms,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Emergency', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: iconColor)),
        iconTheme: IconThemeData(color: iconColor),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: isDarkMode ? Colors.black : Colors.white),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 19),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 12),
                  child: Text(
                    "In case of emergency, press 'Call Now' and a call will be made to your emergency number.",
                    style: TextStyle(color: iconColor, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionCard(title: 'Call Now', icon: Icons.call, isDarkMode: isDarkMode, onTap: onStartCall),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "Press 'Send SMS Now' so that your location will reach him as message.",
                    style: TextStyle(color: iconColor, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionCard(title: 'Send SMS Now', icon: Icons.sms, isDarkMode: isDarkMode, onTap: onSendSms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required bool isDarkMode, required VoidCallback onTap}) {
    return SizedBox(
      width: 240,
      height: 150,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode ? const [Color(0xFF1F1A24), Color(0xFF2A2234)] : const [Colors.white, Color(0xFFF7ECFF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? Colors.deepPurpleAccent.withOpacity(0.25) : const Color(0xFFE5D6F8)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: isDarkMode ? const [Colors.deepPurpleAccent, Color(0xFF7E57C2)] : const [Color(0xFFF0B8F6), Color(0xFFE0C4FF)]),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


