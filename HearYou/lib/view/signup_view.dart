import 'package:flutter/material.dart';

class SignUpView extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool acceptTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onShowTerms;
  final ValueChanged<bool> onChangeAccept;
  final VoidCallback onSubmit;
  final VoidCallback onGoToLogin;

  const SignUpView({
    super.key,
    required this.isDarkMode,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.acceptTerms,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onShowTerms,
    required this.onChangeAccept,
    required this.onSubmit,
    required this.onGoToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: isDarkMode
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Colors.grey[900]!, Colors.black87],
                ),
              )
            : const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign Up', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                  const SizedBox(height: 30),
                  _InputField(label: 'Full Name', hint: 'Enter your full name', icon: Icons.person_outline, isDarkMode: isDarkMode, controller: nameController),
                  const SizedBox(height: 20),
                  _InputField(label: 'Email', hint: 'Enter your email', icon: Icons.email_outlined, isDarkMode: isDarkMode, controller: emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _InputField(label: 'Password', hint: 'Enter your password', icon: Icons.lock_outline, isPassword: true, isDarkMode: isDarkMode, controller: passwordController, obscureText: obscurePassword, toggleObscure: onTogglePassword),
                  const SizedBox(height: 20),
                  _InputField(label: 'Confirm Password', hint: 'Confirm your password', icon: Icons.lock_outline, isPassword: true, isDarkMode: isDarkMode, controller: confirmPasswordController, obscureText: obscureConfirmPassword, toggleObscure: onToggleConfirmPassword),
                  const SizedBox(height: 20),
                  GestureDetector(onTap: onShowTerms, child: const Text('Terms and Conditions', style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue))),
                  Row(children: [
                    Checkbox(value: acceptTerms, onChanged: (v) => onChangeAccept(v ?? false)),
                    const Expanded(child: Text('I accept all terms and conditions')),
                  ]),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), backgroundColor: isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6)),
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIGN UP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(onTap: onGoToLogin, child: const Text.rich(TextSpan(text: 'Already have an account? ', children: [TextSpan(text: 'Login', style: TextStyle(fontWeight: FontWeight.bold))]))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isDarkMode;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? toggleObscure;
  final TextInputType? keyboardType;

  const _InputField({super.key, required this.label, required this.hint, required this.icon, this.isPassword = false, required this.isDarkMode, required this.controller, this.obscureText = false, this.toggleObscure, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: isDarkMode ? Colors.white : null),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility), onPressed: toggleObscure) : null,
          hintText: hint,
          hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
          filled: true,
          fillColor: isDarkMode ? Colors.black45 : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.grey.shade300, width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.grey.shade300, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.grey.shade300, width: 1.2)),
        ),
      ),
    ]);
  }
}


