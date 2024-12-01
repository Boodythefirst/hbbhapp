import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hbbh/services/onboarding_service.dart';
import 'package:hbbh/services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  final AuthService _authService = AuthService();

  int _currentPage = 0;
  String _name = '';
  String _ageGroup = '';
  String _visitFrequency = '';
  final List<String> _selectedInterests = [];
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _ageGroups = ['16-20', '21-25', '26-30', '31-35', '36+'];

  final List<Map<String, String>> _frequencies = [
    {'value': 'First time', 'description': 'This is my first time in Riyadh'},
    {'value': 'Occasional', 'description': 'I visit Riyadh a few times a year'},
    {'value': 'Frequent', 'description': 'I visit Riyadh often'},
    {'value': 'Resident', 'description': 'I live in Riyadh'},
  ];

  final List<String> _interests = [
    '☕ Cafes',
    '🍽️ Restaurants',
    '🛍️ Shopping',
    '🌳 Parks',
    '🏛️ Museums',
    '🎨 Art Galleries',
    '🏀 Sports',
    '🌃 Nightlife',
    '🏰 Historical Sites',
    '🎭 Movies',
    '🎵 Music Venues',
    '🏞️ Outdoor Activities'
  ];

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    try {
      // Try to get data from Firestore first
      final userData = await _authService.getUserData();

      if (userData.isNotEmpty) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _name = userData['name'] ?? '';
          _ageGroup = userData['ageGroup'] ?? '';
          _visitFrequency = userData['visitFrequency'] ?? '';
          _selectedInterests
              .addAll(List<String>.from(userData['interests'] ?? []));
        });
        return;
      }

      // Fall back to local storage if Firestore data is empty
      final localData = await _onboardingService.getOnboardingData();
      setState(() {
        _nameController.text = localData['name'] ?? '';
        _name = localData['name'] ?? '';
        _ageGroup = localData['ageGroup'] ?? '';
        _visitFrequency = localData['visitFrequency'] ?? '';
        _selectedInterests.addAll(localData['interests'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First update the onboarding data in Firestore
      await _authService.updateUserOnboardingData(
        name: _name,
        ageGroup: _ageGroup,
        visitFrequency: _visitFrequency,
        interests: _selectedInterests,
      );

      // Then update local storage through onboarding service
      await _onboardingService.saveOnboardingData(
        name: _name,
        ageGroup: _ageGroup,
        visitFrequency: _visitFrequency,
        interests: _selectedInterests,
      );

      // Mark onboarding as complete in local storage
      await _onboardingService.completeOnboarding();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _completeOnboarding(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getScreenTitle(),
          style: GoogleFonts.ibmPlexSans(),
        ),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildNameScreen(),
            _buildAgeScreen(),
            _buildFrequencyScreen(),
            _buildInterestsScreen(),
          ],
        ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (_currentPage) {
      case 0:
        return 'Welcome';
      case 1:
        return 'Age Group';
      case 2:
        return 'Visit Frequency';
      case 3:
        return 'Your Interests';
      default:
        return 'Welcome';
    }
  }

  Widget _buildNameScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What should we call you? 😊',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildNextButton(
              () {
                if (_formKey.currentState!.validate()) {
                  _nextPage();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Which age group do you belong to? 🎂',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._ageGroups.map((age) => _buildAgeGroupButton(age)),
          const SizedBox(height: 24),
          _buildNextButton(
            () => _nextPage(),
            enabled: _ageGroup.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How often do you visit Riyadh? 🏙️',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._frequencies.map((freq) => _buildFrequencyButton(freq)),
          const SizedBox(height: 24),
          _buildNextButton(
            () => _nextPage(),
            enabled: _visitFrequency.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What are you into? 🤔',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _interests
                  .map((interest) => _buildInterestChip(interest))
                  .toList(),
            ),
          ),
          _buildNextButton(
            () => _completeOnboarding(),
            enabled: _selectedInterests.isNotEmpty,
            isLastPage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupButton(String age) {
    bool isSelected = _ageGroup == age;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _ageGroup = age;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Theme.of(context).primaryColor : Colors.white,
          foregroundColor:
              isSelected ? Colors.white : Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(age),
      ),
    );
  }

  Widget _buildFrequencyButton(Map<String, String> frequency) {
    bool isSelected = _visitFrequency == frequency['value'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _visitFrequency = frequency['value']!;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Theme.of(context).primaryColor : Colors.white,
          foregroundColor:
              isSelected ? Colors.white : Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          children: [
            Text(
              frequency['value']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              frequency['description']!,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    return FilterChip(
      label: Text(interest),
      selected: _selectedInterests.contains(interest),
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color:
            _selectedInterests.contains(interest) ? Colors.white : Colors.black,
      ),
      showCheckmark: false,
      pressElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: _selectedInterests.contains(interest)
            ? Theme.of(context).primaryColor
            : Colors.black,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedInterests.add(interest);
          } else {
            _selectedInterests.remove(interest);
          }
        });
      },
    );
  }

  Widget _buildNextButton(
    VoidCallback onPressed, {
    bool enabled = true,
    bool isLastPage = false,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : (enabled ? onPressed : null),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            enabled ? Theme.of(context).primaryColor : Colors.grey[300],
        foregroundColor: enabled ? Colors.white : Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              isLastPage ? 'Finish' : 'Next',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingProgressIndicator({
    Key? key,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentPage
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}
