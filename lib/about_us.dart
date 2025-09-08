import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Text(
          'About Us',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Hear You App',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hear You is a smart assistance app designed specifically to support deaf mothers in their daily lives. '
                'Using real-time alerts, it notifies mothers when their baby cries, detects knocks at the door, phone calls, '
                'and even tracks the baby\'s sleep state. The app connects to a wearable device (like a smart bracelet) that vibrates to alert the mother '
                'instantly. Our goal is to create a more inclusive, safe, and confident parenting experience using accessible technology and smart detection features.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [Colors.deepPurpleAccent, Color(0xFF7E57C2)]
                            : [Color(0xFFF0B8F6), Color(0xFFE0C4FF)],
                      ),
                    ),
                    child: Icon(Icons.email, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'hear.you.mt@gmail.com',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [Colors.deepPurpleAccent, Color(0xFF7E57C2)]
                            : [Color(0xFFF0B8F6), Color(0xFFE0C4FF)],
                      ),
                    ),
                    child: Icon(Icons.phone, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '+96176722215',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Developed by: Mayssan Al Ashkar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
