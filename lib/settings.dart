import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_info_page.dart';
import 'help.dart';
import 'logout.dart';
import 'about_us.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsPage extends StatefulWidget {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          isNotificationsEnabled = doc['notificationsEnabled'] ?? true;
        });
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
    final TextEditingController _currentPasswordController =
        TextEditingController();
    final TextEditingController _newPasswordController =
        TextEditingController();
    final TextEditingController _confirmPasswordController =
        TextEditingController();
    bool _isLoading = false;
    bool _isCurrentPasswordVisible = false;
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
                          controller: _currentPasswordController,
                          obscureText: !_isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Current Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isCurrentPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isCurrentPasswordVisible =
                                      !_isCurrentPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: !_isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            border: OutlineInputBorder(),
                            helperText: 'At least 6 characters',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isCurrentPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isCurrentPasswordVisible =
                                      !_isCurrentPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Confirm New Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isCurrentPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isCurrentPasswordVisible =
                                      !_isCurrentPasswordVisible;
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
                          _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                if (_currentPasswordController.text.isEmpty ||
                                    _newPasswordController.text.isEmpty ||
                                    _confirmPasswordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please fill all fields'),
                                    ),
                                  );
                                  return;
                                }

                                if (_newPasswordController.text !=
                                    _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'New passwords do not match',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (_newPasswordController.text.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password must be at least 6 characters',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isLoading = true);

                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null && user.email != null) {
                                    AuthCredential credential =
                                        EmailAuthProvider.credential(
                                          email: user.email!,
                                          password:
                                              _currentPasswordController.text,
                                        );

                                    await user.reauthenticateWithCredential(
                                      credential,
                                    );
                                    await user.updatePassword(
                                      _newPasswordController.text,
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
                                  setState(() => _isLoading = false);
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
                                  setState(() => _isLoading = false);
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
                          _isLoading
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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor =
        isDarkMode ? Colors.black : Color.fromARGB(255, 236, 184, 201);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
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
                  ListTile(
                    leading: Image.asset('images/changename.png', width: 30),
                    title: Text(
                      'Change Name',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: _showNameChangeDialog,
                  ),
                  ListTile(
                    leading: Image.asset('images/changepass.png', width: 30),
                    title: Text('Change Password'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: _showChangePasswordDialog,
                  ),
                  ListTile(
                    leading: Image.asset('images/editprofile.png', width: 30),
                    title: Text('Edit Info'),
                    trailing: Icon(Icons.arrow_forward_ios),
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
                  ListTile(
                    leading: Image.asset('images/notification.png', width: 30),
                    title: Text('Notifications'),
                    trailing: Switch(
                      value: isNotificationsEnabled,
                      onChanged: (bool value) async {
                        setState(() {
                          isNotificationsEnabled = value;
                        });

                        final DatabaseReference ref = FirebaseDatabase.instance
                            .ref("notification_control");
                        await ref.set(value ? "enable" : "disable");
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    leading: Image.asset('images/logout.png', width: 30),
                    title: Text('Log Out'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LogoutPage()),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    'About',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    leading: Image.asset('images/about.png', width: 27),
                    title: Text('About Us'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutUs()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Image.asset('images/help.png', width: 40),
                    title: Text('Help'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  Help(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;

                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
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
