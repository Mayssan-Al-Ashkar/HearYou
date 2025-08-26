import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class Help extends StatefulWidget {
  @override
  _HelpState createState() => _HelpState();
}

class _HelpState extends State<Help> {
  String _selectedSubject = "General information / Contact";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();    Future<void> _setUserEmail() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          _emailController.text = user.email ?? '';
          
          _nameController.text = doc.data()?['name'] ?? user.displayName ?? '';
        });
      }
    }   
    _setUserEmail();
  }

  Future<void> _setUserEmail() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    setState(() {
      if (user.email != null) {
        _emailController.text = user.email!;
      }
      if (user.displayName != null) {
        _nameController.text = user.displayName!;
      }
    });
  }
}


  InputDecoration _inputDecoration(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.white,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.purple),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Future<void> sendFormspreeEmail() async {
    final url = Uri.parse('https://formspree.io/f/mgvkoved');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': _nameController.text,
        'email': _emailController.text,
        'subject': _selectedSubject,
        'message': _messageController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sent successfully!')),
      );
      _nameController.clear();
      _messageController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Help / Contact"),
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Align(
  alignment: Alignment.centerLeft,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Name:",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      SizedBox(height: 4),
      Text(
        _nameController.text.isNotEmpty ? _nameController.text : 'N/A',
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      SizedBox(height: 16),
      Text(
        "Email:",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      SizedBox(height: 4),
      Text(
        _emailController.text.isNotEmpty ? _emailController.text : 'N/A',
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      SizedBox(height: 20),
    ],
  ),
),

                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "CHOOSE A SUBJECT...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                RadioListTile(
                  title: Text("General information / Contact",
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black)),
                  value: "General information / Contact",
                  groupValue: _selectedSubject,
                  activeColor: Colors.purple,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                  },
                ),
                RadioListTile(
                  title: Text("Suggest a feature",
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black)),
                  value: "Suggest a feature",
                  groupValue: _selectedSubject,
                  activeColor: Colors.purple,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                  },
                ),
                RadioListTile(
                  title: Text("Report a Problem",
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black)),
                  value: "Report a Problem",
                  groupValue: _selectedSubject,
                  activeColor: Colors.purple,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                  },
                ),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: _inputDecoration("Message"),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 227, 148, 240),
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: sendFormspreeEmail,
                  child: Text(
                    "Send",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 30),
                Divider(color: isDark ? Colors.white54 : Colors.black),
                Text(
                  "Feedback",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "If you encounter any issues, have suggestions, or would like to request new features, please feel free to reach out to us by email — we’re always happy to hear from you and improve the app!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
