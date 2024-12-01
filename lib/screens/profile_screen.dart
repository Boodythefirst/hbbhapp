import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hbbh/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _authService.getCurrentUser();
      final userData = await _authService.getUserData();

      setState(() {
        _userInfo = userData;
        _isGuest = currentUser == null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load user information. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.ibmPlexSans()),
        automaticallyImplyLeading: false,
        actions: [
          if (_isGuest)
            TextButton(
              onPressed: () => context.push('/signin'),
              child: Text(
                'Sign In',
                style: GoogleFonts.ibmPlexSans(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildStatsSection(),
                    _buildProfileSections(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage:
                      const AssetImage('assets/images/default_profile.png'),
                  child: _userInfo?['photoUrl'] != null
                      ? null
                      : Text(
                          (_userInfo?['name'] ?? 'G')[0].toUpperCase(),
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                ),
              ),
              if (!_isGuest)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Change profile picture coming soon!'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userInfo?['name'] ?? 'Guest User',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!_isGuest && _userInfo?['email'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _userInfo!['email'],
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Visited', '12'),
          _buildStatDivider(),
          _buildStatItem('Bookmarks', '24'),
          _buildStatDivider(),
          _buildStatItem('Reviews', '8'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildProfileSections() {
    return Column(
      children: [
        _buildSection(
          'Personal Information',
          [
            _buildInfoTile(
              Icons.cake,
              'Age Group',
              _userInfo?['ageGroup'] ?? 'Not specified',
            ),
            _buildInfoTile(
              Icons.calendar_today,
              'Visit Frequency',
              _userInfo?['visitFrequency'] ?? 'Not specified',
            ),
            _buildInfoTile(
              Icons.interests,
              'Interests',
              _formatInterests(_userInfo?['interests']),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildActionButton(
                'Edit Profile',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile coming soon!')),
                  );
                },
                isPrimary: true,
              ),
              if (_isGuest)
                _buildActionButton(
                  'Create Account',
                  onPressed: () => context.push('/signup'),
                  isPrimary: false,
                ),
              if (!_isGuest)
                _buildActionButton(
                  'Log Out',
                  onPressed: _handleLogout,
                  isDanger: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label, {
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? Theme.of(context).primaryColor
                : isDanger
                    ? Colors.red[50]
                    : Colors.grey[50],
            foregroundColor: isPrimary
                ? Colors.white
                : isDanger
                    ? Colors.red
                    : Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isPrimary
                  ? BorderSide.none
                  : BorderSide(
                      color: isDanger ? Colors.red : Colors.grey[300]!,
                    ),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatInterests(dynamic interests) {
    if (interests == null) return 'Not specified';
    if (interests is! List) return 'Not specified';
    return interests.join(', ');
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
