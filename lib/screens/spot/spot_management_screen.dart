// lib/screens/spot/spot_management_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hbbh/models/spot_model.dart';
import 'package:hbbh/services/spot_service.dart';
import 'package:hbbh/services/auth_service.dart';

class SpotManagementScreen extends StatefulWidget {
  const SpotManagementScreen({Key? key}) : super(key: key);

  @override
  _SpotManagementScreenState createState() => _SpotManagementScreenState();
}

class _SpotManagementScreenState extends State<SpotManagementScreen> {
  final SpotService _spotService = SpotService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  SpotModel? _spot;

  @override
  void initState() {
    super.initState();
    _loadSpotData();
  }

  Future<void> _loadSpotData() async {
    setState(() => _isLoading = true);
    try {
      final spot = await _spotService.getCurrentUserSpot();
      setState(() => _spot = spot);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading spot data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleToggleActive() async {
    try {
      if (_spot == null) return;

      await _spotService.updateSpotStatus(
        spotId: _spot!.id,
        isActive: !_spot!.isActive,
      );

      // Refresh spot data
      await _loadSpotData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_spot!.isActive
                ? 'Your spot is now visible to users'
                : 'Your spot is now hidden from users'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Your Spot', style: GoogleFonts.ibmPlexSans()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _spot == null
              ? _buildNoSpotFound()
              : RefreshIndicator(
                  onRefresh: _loadSpotData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildStatusSection(),
                        _buildStatsSection(),
                        _buildActionsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoSpotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No spot found',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Register your spot to get started',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/spot-onboarding'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Register Spot'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _spot!.thumbnailUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _spot!.name,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 16,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _spot!.isVerified ? Colors.green[50] : Colors.yellow[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _spot!.isVerified
                    ? Colors.green[200]!
                    : Colors.yellow[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _spot!.isVerified
                      ? Icons.verified_outlined
                      : Icons.pending_outlined,
                  color: _spot!.isVerified
                      ? Colors.green[700]
                      : Colors.yellow[900],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _spot!.isVerified
                            ? 'Verified Spot'
                            : 'Pending Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _spot!.isVerified
                              ? Colors.green[700]
                              : Colors.yellow[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _spot!.isVerified
                            ? 'Your spot has been verified by our team'
                            : 'Your spot is being reviewed by our team',
                        style: TextStyle(
                          color: _spot!.isVerified
                              ? Colors.green[700]
                              : Colors.yellow[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_spot!.isVerified)
            SwitchListTile(
              title: const Text('Show spot to users'),
              subtitle: Text(
                _spot!.isActive
                    ? 'Your spot is visible in search results'
                    : 'Your spot is hidden from search results',
              ),
              value: _spot!.isActive,
              onChanged: (value) => _handleToggleActive(),
              activeColor: Theme.of(context).primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Views',
                  '2.5K',
                  Icons.visibility_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Bookmarks',
                  '156',
                  Icons.bookmark_outline,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Rating',
                  '4.8',
                  Icons.star_outline,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            'Edit Spot Information',
            'Update your spot details, images, and more',
            Icons.edit_outlined,
            onTap: () => context.push('/spot-edit'),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            'View Analytics',
            'See detailed statistics and performance',
            Icons.analytics_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics coming soon!'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            'Manage Reviews',
            'View and respond to customer reviews',
            Icons.reviews_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review management coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!_spot!.isVerified) return Colors.orange;
    if (!_spot!.isActive) return Colors.grey;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (!_spot!.isVerified) return Icons.pending_outlined;
    if (!_spot!.isActive) return Icons.visibility_off_outlined;
    return Icons.check_circle_outline;
  }

  String _getStatusText() {
    if (!_spot!.isVerified) return 'Pending Verification';
    if (!_spot!.isActive) return 'Hidden';
    return 'Active';
  }

  String _formatTimestamp(DateTime timestamp) {
    // Format relative time
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getOpenStatus() {
    // Get current day and time
    final now = DateTime.now();
    final currentDay = _getCurrentDay(now.weekday);

    final hours = _spot!.businessHours[currentDay];
    if (hours == null) return 'Closed';

    final openTime = _parseTimeString(hours['open']!);
    final closeTime = _parseTimeString(hours['close']!);
    final currentTime = TimeOfDay.fromDateTime(now);

    if (_isTimeBetween(currentTime, openTime, closeTime)) {
      return 'Open';
    } else {
      return 'Closed';
    }
  }

  String _getCurrentDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  TimeOfDay _parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool _isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final now = time.hour * 60 + time.minute;
    final opens = start.hour * 60 + start.minute;
    final closes = end.hour * 60 + end.minute;

    if (closes < opens) {
      // Handles cases where closing time is on the next day
      return now >= opens || now <= closes;
    }

    return now >= opens && now <= closes;
  }
}
