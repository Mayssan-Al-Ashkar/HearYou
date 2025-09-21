import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'view/help_view.dart';

class Help extends StatefulWidget {
  const Help({super.key});

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
    super.initState();    Future<void> setUserEmail() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          _emailController.text = user.email ?? '';
          
          _nameController.text = doc.data()?['name'] ?? user.displayName ?? '';
        });
      }
    }   
    setUserEmail();
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


  // Input decoration now lives in the view

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
    return HelpScreenView(
      model: HelpViewModel(
        selectedSubject: _selectedSubject,
        nameController: _nameController,
        emailController: _emailController,
        messageController: _messageController,
      ),
      isDark: isDark,
      onChangeSubject: (value) => setState(() { _selectedSubject = value ?? _selectedSubject; }),
      onSend: sendFormspreeEmail,
    );
  }
}
