import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_info_page.dart';
import 'help.dart';
import 'about_us.dart';
import 'login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isNotificationsEnabled = true;
  String userName = '';
  String userPhotoUrl = '';
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationSetting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadNotificationSetting() async {
    // Load locally first for instant UI, then sync from Firestore if available
    final prefs = await SharedPreferences.getInstance();
    final localValue = prefs.getBool('notificationsEnabled');
    if (localValue != null) {
      setState(() {
        isNotificationsEnabled = localValue;
      });
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          isNotificationsEnabled = doc['notificationsEnabled'] ?? true;
        });
        await prefs.setBool('notificationsEnabled', isNotificationsEnabled);
      }
    }
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      String? photoUrl = currentUser!.photoURL;

      final userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get();

      if (userData.exists) {
        final firestorePhotoUrl = userData.data()?['photoURL'];

        setState(() {
          userName = userData.data()?['name'] ?? '';
          userPhotoUrl = photoUrl ?? firestorePhotoUrl ?? '';
        });
      }

      await currentUser!.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser?.photoURL != null &&
          refreshedUser!.photoURL!.isNotEmpty) {
        setState(() {
          userPhotoUrl = refreshedUser.photoURL!;
        });
      }
    }
  }

  Future<void> _updateUserName() async {
    if (currentUser != null && _nameController.text.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'name': _nameController.text.trim()});

        setState(() {
          userName = _nameController.text.trim();
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Name updated successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name. Please try again.')),
        );
      }
    }
  }

  void _showNameChangeDialog() {
    _nameController.text = userName;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Change Name'),
            content: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter new name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(onPressed: _updateUserName, child: Text('Save')),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController =
        TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isLoading = false;
    bool isCurrentPasswordVisible = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Change Password'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: currentPasswordController,
                          obscureText: !isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Current Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isCurrentPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isCurrentPasswordVisible =
                                      !isCurrentPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: newPasswordController,
                          obscureText: !isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            border: OutlineInputBorder(),
                            helperText: 'At least 6 characters',
                            suffixIcon: IconButton(
                              icon: Icon(
                                isCurrentPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isCurrentPasswordVisible =
                                      !isCurrentPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: !isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Confirm New Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isCurrentPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isCurrentPasswordVisible =
                                      !isCurrentPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (currentPasswordController.text.isEmpty ||
                                    newPasswordController.text.isEmpty ||
                                    confirmPasswordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please fill all fields'),
                                    ),
                                  );
                                  return;
                                }

                                if (newPasswordController.text !=
                                    confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'New passwords do not match',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPasswordController.text.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password must be at least 6 characters',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => isLoading = true);

                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null && user.email != null) {
                                    AuthCredential credential =
                                        EmailAuthProvider.credential(
                                          email: user.email!,
                                          password:
                                              currentPasswordController.text,
                                        );

                                    await user.reauthenticateWithCredential(
                                      credential,
                                    );
                                    await user.updatePassword(
                                      newPasswordController.text,
                                    );
                                    await FirebaseAuth.instance.signOut();

                                    Navigator.pop(context);

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Success'),
                                          content: Text(
                                            'Password changed successfully. Please login again with your new password.',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text('OK'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(
                                                  context,
                                                ).pushNamedAndRemoveUntil(
                                                  '/login',
                                                  (Route<dynamic> route) =>
                                                      false,
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  setState(() => isLoading = false);
                                  String errorMessage =
                                      'Failed to change password';
                                  if (e.code == 'wrong-password') {
                                    errorMessage =
                                        'Current password is incorrect';
                                  } else if (e.code == 'weak-password') {
                                    errorMessage = 'New password is too weak';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                } catch (e) {
                                  setState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'An error occurred. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      child:
                          isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text('Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required bool isDarkMode,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.deepPurpleAccent, const Color(0xFF7E57C2)]
                  : [const Color(0xFFF0B8F6), const Color(0xFFE0C4FF)],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, color: isDarkMode ? Colors.white70 : Colors.black54),
        onTap: onTap,
      ),
    );
  }

  Future<void> _logout() async {
    try {
      try { await GoogleSignIn().signOut(); } catch (_) {}
      try { await FacebookAuth.instance.logOut(); } catch (_) {}
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Background now controlled via AppBar flexibleSpace + body color

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black, 
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black, 
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20, 
                        backgroundColor: Colors.grey[300],
                        child:
                            userPhotoUrl.isNotEmpty
                                ? ClipOval(
                                  child: Image.network(
                                    userPhotoUrl,
                                    width: 40, 
                                    height: 40, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        color: Colors.grey[600],
                                        size: 20,
                                      );
                                    },
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  Icons.person,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        userName.isNotEmpty ? userName : 'User Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  Text(
                    'Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildSettingsCard(
                    icon: Icons.drive_file_rename_outline,
                    title: 'Change Name',
                    isDarkMode: isDarkMode,
                    onTap: _showNameChangeDialog,
                  ),
                  _buildSettingsCard(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    isDarkMode: isDarkMode,
                    onTap: _showChangePasswordDialog,
                  ),
                  _buildSettingsCard(
                    icon: Icons.edit,
                    title: 'Edit Info',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditInfoPage()),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildSettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    isDarkMode: isDarkMode,
                    trailing: Switch(
                      value: isNotificationsEnabled,
                      activeColor: isDarkMode ? Colors.deepPurpleAccent : Color(0xFFF0B8F6),
                      onChanged: (bool value) async {
                        setState(() {
                          isNotificationsEnabled = value;
                        });

                        // Persist locally (device)
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('notificationsEnabled', value);

                        // Persist in Firestore for the current user
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .set({'notificationsEnabled': value}, SetOptions(merge: true));
                        }

                        // Optional: notify other services via Realtime DB
                        final DatabaseReference ref = FirebaseDatabase.instance
                            .ref("notification_control");
                        await ref.set(value ? "enable" : "disable");
                      },
                    ),
                  ),
                  _buildSettingsCard(
                    icon: Icons.description_outlined,
                    title: 'Weekly Reports',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pushNamed(context, '/weeklyReport');
                    },
                  ),
                  // Removed Account section; add Logout button under Help
                  SizedBox(height: 10),
                  Text(
                    'About',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildSettingsCard(
                    icon: Icons.info_outline,
                    title: 'About Us',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutUs()),
                      );
                    },
                  ),
                  _buildSettingsCard(
                    icon: Icons.help_outline,
                    title: 'Help',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => Help(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(250, 50),
                        backgroundColor:
                            isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'LOGOUT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
