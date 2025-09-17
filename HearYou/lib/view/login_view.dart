import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onGoToSignup;

  const LoginView({
    super.key,
    required this.isDarkMode,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onGoogleSignIn,
    required this.onGoToSignup,
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('images/logo.png', height: 100),
                  const SizedBox(height: 12),
                  Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                  const SizedBox(height: 30),
                  _InputField(label: 'Email', hint: 'Type your email', icon: Icons.email_outlined, isDarkMode: isDarkMode, controller: emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _InputField(label: 'Password', hint: 'Type your password', icon: Icons.lock_outline, isPassword: true, obscureText: obscurePassword, toggleObscure: onToggleObscure, isDarkMode: isDarkMode, controller: passwordController),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: onForgotPassword, child: Text('Forgot password?', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54))),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : onLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      backgroundColor: isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  Text('or', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 10),
                  _SocialButton(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('images/Google.png', width: 24, height: 24),
                      const SizedBox(width: 10),
                      const Text('Continue with Google', style: TextStyle(color: Colors.black)),
                    ]),
                    color: Colors.white,
                    borderColor: const Color(0xFFF0B8F6),
                    onPressed: onGoogleSignIn,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: onGoToSignup,
                    child: Text.rich(TextSpan(text: "Don't have an account? ", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54), children: [
                      TextSpan(text: 'Signup', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                    ])),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onPressed;
  final Color? borderColor;
  const _SocialButton({required this.child, required this.color, required this.onPressed, this.borderColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 250,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30), border: Border.all(color: borderColor ?? Colors.grey.shade300)),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(30), onTap: onPressed, child: Center(child: child))),
    );
  }
}


