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
import 'view/settings_view.dart';

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

    return SettingsScreenView(
      model: SettingsViewModel(
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        isNotificationsEnabled: isNotificationsEnabled,
      ),
      isDarkMode: isDarkMode,
      onBack: () => Navigator.pop(context),
      onChangeName: _showNameChangeDialog,
      onChangePassword: _showChangePasswordDialog,
      onEditInfo: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => EditInfoPage()));
      },
      onToggleNotifications: (bool value) async {
        setState(() { isNotificationsEnabled = value; });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notificationsEnabled', value);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'notificationsEnabled': value}, SetOptions(merge: true));
        }
        final DatabaseReference ref = FirebaseDatabase.instance.ref("notification_control");
        await ref.set(value ? "enable" : "disable");
      },
      onWeeklyReports: () { Navigator.pushNamed(context, '/weeklyReport'); },
      onAboutUs: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AboutUs())); },
      onHelp: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Help(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      onLogout: _logout,
    );
  }
}
