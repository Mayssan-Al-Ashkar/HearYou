import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 236, 184, 201),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Text(
                'Developed by: Mayssan Al Ashkar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
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
                  Icon(Icons.email, color: isDarkMode ? Colors.white : Colors.black),
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
                  Icon(Icons.phone, color: isDarkMode ? Colors.white : Colors.black),
                  const SizedBox(width: 10),
                  Text(
                    '+96176722215',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
