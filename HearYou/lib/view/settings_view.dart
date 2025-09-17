import 'package:flutter/material.dart';

class SettingsViewModel {
  final String userName;
  final String userPhotoUrl;
  final bool isNotificationsEnabled;

  const SettingsViewModel({
    required this.userName,
    required this.userPhotoUrl,
    required this.isNotificationsEnabled,
  });
}

class SettingsScreenView extends StatelessWidget {
  final SettingsViewModel model;
  final bool isDarkMode;

  final VoidCallback onBack;
  final VoidCallback onChangeName;
  final VoidCallback onChangePassword;
  final VoidCallback onEditInfo;
  final ValueChanged<bool> onToggleNotifications;
  final VoidCallback onWeeklyReports;
  final VoidCallback onAboutUs;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  const SettingsScreenView({
    super.key,
    required this.model,
    required this.isDarkMode,
    required this.onBack,
    required this.onChangeName,
    required this.onChangePassword,
    required this.onEditInfo,
    required this.onToggleNotifications,
    required this.onWeeklyReports,
    required this.onAboutUs,
    required this.onHelp,
    required this.onLogout,
  });

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

  @override
  Widget build(BuildContext context) {
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
          onPressed: onBack,
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
                        child: model.userPhotoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  model.userPhotoUrl,
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
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        model.userName.isNotEmpty ? model.userName : 'User Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _buildSettingsCard(
                    icon: Icons.drive_file_rename_outline,
                    title: 'Change Name',
                    isDarkMode: isDarkMode,
                    onTap: onChangeName,
                  ),
                  _buildSettingsCard(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    isDarkMode: isDarkMode,
                    onTap: onChangePassword,
                  ),
                  _buildSettingsCard(
                    icon: Icons.edit,
                    title: 'Edit Info',
                    isDarkMode: isDarkMode,
                    onTap: onEditInfo,
                  ),
                  const SizedBox(height: 10),
                  const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _buildSettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    isDarkMode: isDarkMode,
                    trailing: Switch(
                      value: model.isNotificationsEnabled,
                      activeColor: isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                      onChanged: onToggleNotifications,
                    ),
                  ),
                  _buildSettingsCard(
                    icon: Icons.description_outlined,
                    title: 'Weekly Reports',
                    isDarkMode: isDarkMode,
                    onTap: onWeeklyReports,
                  ),
                  const SizedBox(height: 10),
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _buildSettingsCard(
                    icon: Icons.info_outline,
                    title: 'About Us',
                    isDarkMode: isDarkMode,
                    onTap: onAboutUs,
                  ),
                  _buildSettingsCard(
                    icon: Icons.help_outline,
                    title: 'Help',
                    isDarkMode: isDarkMode,
                    onTap: onHelp,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: onLogout,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(250, 50),
                        backgroundColor: isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'LOGOUT',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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


