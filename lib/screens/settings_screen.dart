import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hbbh/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.ibmPlexSans()),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          _buildSection(
            'General',
            [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(_selectedLanguage),
                onTap: () {
                  // Show language selection dialog
                  _showLanguageDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: Text(_getThemeText()),
                onTap: () {
                  // Show theme selection dialog
                  _showThemeDialog();
                },
              ),
            ],
          ),
          _buildSection(
            'Notifications',
            [
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Enable Notifications'),
                subtitle: const Text('Get updates about new spots and events'),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.location_on),
                title: const Text('Location Services'),
                subtitle: const Text('Enable location-based recommendations'),
                value: _locationEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _locationEnabled = value;
                  });
                },
              ),
            ],
          ),
          _buildSection(
            'Account',
            [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                onTap: () {
                  // Navigate to profile editing screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                onTap: () {
                  // Navigate to password change screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Settings'),
                onTap: () {
                  // Navigate to privacy settings
                },
              ),
            ],
          ),
          _buildSection(
            'Support',
            [
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help Center'),
                onTap: () {
                  // Navigate to help center
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('Send Feedback'),
                onTap: () {
                  // Open feedback form
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
          _buildSection(
            'Actions',
            [
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[400]),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red[400]),
                ),
                onTap: () async {
                  await _authService.signOut();
                  if (mounted) {
                    context.go('/');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  String _getThemeText() {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                trailing: _selectedLanguage == 'English'
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'English';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('العربية'),
                trailing: _selectedLanguage == 'العربية'
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'العربية';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('System Default'),
                trailing: _themeMode == ThemeMode.system
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.system;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Light'),
                trailing: _themeMode == ThemeMode.light
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.light;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Dark'),
                trailing: _themeMode == ThemeMode.dark
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.dark;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About HBBH', style: GoogleFonts.ibmPlexSans()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0',
                style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'HBBH is your guide to discovering the best spots in Riyadh. Find cafes, restaurants, shopping destinations, and entertainment venues all in one place.',
              ),
              const SizedBox(height: 16),
              const Text('© 2024 HBBH. All rights reserved.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
