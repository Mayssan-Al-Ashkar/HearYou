import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must accept the terms and conditions")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = 
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await userCredential.user?.sendEmailVerification();
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please check your email for verification link"),
          duration: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred during registration.";

      if (e.code == 'weak-password') {
        errorMessage = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "An account already exists for that email.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Please enter a valid email address.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

void _showTermsDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Terms and Conditions"),
        content: SingleChildScrollView(
          child: Text(
            "• You must provide correct and real information when signing up.\n\n"
            "• Keep your password safe. If someone else uses your account, it's your responsibility.\n\n"
            "• We collect some data to improve the app, but we don’t share your personal info without permission.\n\n"
            "• You are not allowed to hack, change, or misuse the app.\n\n"
            "• We may update the app from time to time to fix bugs or add new features.\n\n"
            "• The app may sometimes be unavailable due to maintenance.\n\n"
            "• If you break the rules, we have the right to suspend or delete your account.",
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.black, Colors.grey[900]!, Colors.black87]
                : [
                    Color.fromARGB(255, 236, 184, 201),
                    Colors.white,
                    Color.fromARGB(255, 212, 184, 243),
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 30),
                  InputField(
                    label: "Full Name",
                    hint: "Enter your full name",
                    icon: Icons.person_outline,
                    isDarkMode: isDarkMode,
                    controller: _nameController,
                  ),
                  SizedBox(height: 20),
                  InputField(
                    label: "Email",
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                    isDarkMode: isDarkMode,
                    controller: _emailController,
                  ),
                  SizedBox(height: 20),
                  InputField(
                    label: "Password",
                    hint: "Enter your password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isDarkMode: isDarkMode,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    toggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  InputField(
                    label: "Confirm Password",
                    hint: "Confirm your password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isDarkMode: isDarkMode,
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    toggleObscure: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _showTermsDialog,
                    child: Text(
                      "Terms and Conditions",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: Text("I accept all terms and conditions"),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: isDarkMode
                          ? Colors.deepPurpleAccent
                          : Color.fromARGB(255, 225, 141, 239),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "SIGN UP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
