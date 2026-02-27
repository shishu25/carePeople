import 'package:flutter/material.dart';
import '../patient/patient_login.dart';
import '../mixed/appbar.dart';

class SettingsPage extends StatefulWidget {
  final String phoneNumber;

  const SettingsPage({super.key, required this.phoneNumber});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  String _appAppearance = 'System';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(title: 'Settings', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  children: [
                    // Notifications Card
                    _buildSettingsCard(
                      child: SwitchListTile(
                        title: const Text(
                          'Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        secondary: const Icon(Icons.notifications_outlined),
                        value: _notificationsEnabled,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),

                    // App Appearance Card
                    _buildSettingsCard(
                      child: ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text(
                          'App Appearance',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: _appAppearance,
                          underline: const SizedBox(),
                          items: ['System', 'Light', 'Dark']
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _appAppearance = value!;
                            });
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),

                    // Security, Terms, Privacy, Help Card
                    _buildSettingsCard(
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.security_outlined,
                            title: 'Security',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Security settings coming soon!',
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.description_outlined,
                            title: 'Terms & Conditions',
                            trailing: Icons.link,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Opening Terms & Conditions...',
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            trailing: Icons.link,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Opening Privacy Policy...'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.help_outline,
                            title: 'Help',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Help center coming soon!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),

                    // Invite & Logout Card
                    _buildSettingsCard(
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.person_add_outlined,
                            title: 'Invite a Friend',
                            trailing: Icons.link,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share feature coming soon!'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.logout,
                            title: 'Logout',
                            textColor: Colors.red,
                            onTap: () => _showLogoutDialog(context),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenWidth * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    IconData? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor,
        ),
      ),
      trailing: Icon(trailing ?? Icons.chevron_right, color: Colors.grey[600]),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to login and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientLoginPage(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
