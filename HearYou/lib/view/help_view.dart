import 'package:flutter/material.dart';

class HelpViewModel {
  final String selectedSubject;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController messageController;

  const HelpViewModel({
    required this.selectedSubject,
    required this.nameController,
    required this.emailController,
    required this.messageController,
  });
}

class HelpScreenView extends StatelessWidget {
  final HelpViewModel model;
  final bool isDark;
  final void Function(String?) onChangeSubject;
  final VoidCallback onSend;

  const HelpScreenView({
    super.key,
    required this.model,
    required this.isDark,
    required this.onChangeSubject,
    required this.onSend,
  });

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: isDark ? Colors.black45 : Colors.white,
      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isDark ? Colors.white : Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isDark ? Colors.white : Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isDark ? Colors.white : Colors.grey.shade300, width: 1.2),
      ),
      prefixIconColor: isDark ? Colors.white : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Help / Contact', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(color: isDark ? Colors.black : Colors.white),
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
                      Text('Name:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black45 : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isDark ? Colors.white : Colors.grey.shade300, width: 1),
                        ),
                        child: Text(model.nameController.text.isNotEmpty ? model.nameController.text : 'N/A', style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                      ),
                      const SizedBox(height: 16),
                      Text('Email:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black45 : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isDark ? Colors.white : Colors.grey.shade300, width: 1),
                        ),
                        child: Text(model.emailController.text.isNotEmpty ? model.emailController.text : 'N/A', style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CHOOSE A SUBJECT...', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                ),
                RadioListTile(
                  title: Text('General information / Contact', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  value: 'General information / Contact',
                  groupValue: model.selectedSubject,
                  activeColor: isDark ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                  contentPadding: EdgeInsets.zero,
                  onChanged: onChangeSubject,
                ),
                RadioListTile(
                  title: Text('Suggest a feature', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  value: 'Suggest a feature',
                  groupValue: model.selectedSubject,
                  activeColor: isDark ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                  contentPadding: EdgeInsets.zero,
                  onChanged: onChangeSubject,
                ),
                RadioListTile(
                  title: Text('Report a Problem', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  value: 'Report a Problem',
                  groupValue: model.selectedSubject,
                  activeColor: isDark ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                  contentPadding: EdgeInsets.zero,
                  onChanged: onChangeSubject,
                ),
                TextField(
                  controller: model.messageController,
                  maxLines: 4,
                  decoration: _inputDecoration('Message'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 50),
                    backgroundColor: isDark ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  onPressed: onSend,
                  child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 30),
                Divider(color: isDark ? Colors.white54 : Colors.black),
                Text('Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 10),
                Text(
                  'If you encounter any issues, have suggestions, or would like to request new features, please feel free to reach out to us by email — we’re always happy to hear from you and improve the app!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


