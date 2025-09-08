import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'login.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  _LogoutPageState createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _signedInWithEmailPassword = true; 

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      final providerData = user.providerData;
      if (providerData.any((info) => info.providerId == 'google.com')) {
        _signedInWithEmailPassword = false;
      } else {
        _signedInWithEmailPassword = true;
      }

      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _logout() async {
    if (_emailController.text.isEmpty ||
        (_signedInWithEmailPassword && _passwordController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _signedInWithEmailPassword
                ? "Please enter your email and password to logout"
                : "Please enter your email to logout",
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_signedInWithEmailPassword) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        if (_emailController.text.trim() != _auth.currentUser?.email) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Email does not match the signed-in Google account.',
          );
        }
      }

      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'lastLogout': FieldValue.serverTimestamp()});
      }

      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Invalid credentials. Please try again.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = "Incorrect email or password.";
      } else if (e.code == 'invalid-email') {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred during logout")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sendLogoutConfirmationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirmationLink =
        'https://your-app.firebaseapp.com/confirm-logout?uid=${user.uid}';

    await FirebaseFirestore.instance
        .collection('logout_requests')
        .doc(user.uid)
        .set({
          'email': user.email,
          'confirmed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Confirmation email sent! Please open the link to confirm logout.",
        ),
      ),
    );

    print("OPEN THIS LINK TO CONFIRM LOGOUT: $confirmationLink");
  }

  Future<void> _checkLogoutConfirmation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('logout_requests')
            .doc(user.uid)
            .get();
    if (doc.exists && doc.data()?['confirmed'] == true) {
      await _logout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout not yet confirmed from email.")),
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Confirm Logout"),
            content: Text(
              "We've sent a confirmation email to your address. Please click the link in the email, then press CONFIRM LOGOUT.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          if (_signedInWithEmailPassword) {
                            await _logout();
                          } else {
                            await _checkLogoutConfirmation();
                          }
                        },
                child: Text("Confirm Logout"),
              ),
            ],
          ),
    );
  }

  Future<void> _handleGoogleLogout() async {
    await _sendLogoutConfirmationEmail();
    _showLogoutConfirmationDialog();
  }


  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Logout', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _signedInWithEmailPassword
                    ? "Confirm your email and password to logout"
                    : "Confirm your email to logout",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: [AutofillHints.email],
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 20),
              if (_signedInWithEmailPassword)
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _logout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                  backgroundColor: isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "LOGOUT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
