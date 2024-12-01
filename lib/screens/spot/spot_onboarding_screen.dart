// lib/screens/spot/spot_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hbbh/constants/app_constants.dart';
import 'package:hbbh/services/auth_service.dart';
import 'package:hbbh/services/storage_service.dart';
import 'package:hbbh/services/spot_service.dart';
import 'package:hbbh/models/spot_model.dart';
import 'package:hbbh/widgets/spot/onboarding_step_indicator.dart';
import 'package:hbbh/widgets/spot/image_upload_card.dart';
import 'package:hbbh/widgets/spot/business_hours_picker.dart';

class SpotOnboardingScreen extends StatefulWidget {
  const SpotOnboardingScreen({Key? key}) : super(key: key);

  @override
  _SpotOnboardingScreenState createState() => _SpotOnboardingScreenState();
}

class _SpotOnboardingScreenState extends State<SpotOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _spotService = SpotService();

  int _currentStep = 0;
  bool _isLoading = false;
  String? _thumbnailUrl;
  List<String> _carouselUrls = [];
  bool _isUploadingThumbnail = false;
  bool _isUploadingCarousel = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _googleMapsController = TextEditingController();

  // Form values
  String _selectedType = SpotService.spotTypes.first;
  String _selectedPriceRange = SpotService.priceRanges.first;
  String _selectedNeighborhood = AppConstants.riyadhNeighborhoods.first;
  List<String> _selectedTags = [];
  Map<String, Map<String, String>> _businessHours =
      AppConstants.defaultBusinessHours;
  Map<String, String> _socialLinks = {};

  final List<String> _steps = [
    'Basic Info',
    'Location',
    'Images',
    'Details',
    'Hours',
    'Final',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _googleMapsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      String? neighborhood;
      try {
        neighborhood = await _spotService.extractNeighborhoodFromGoogleMapsLink(
          _googleMapsController.text,
        );
      } catch (e) {
        // If extraction fails, use selected neighborhood
        neighborhood = _selectedNeighborhood;
      }

      final spot = SpotModel(
        id: user.uid,
        ownerId: user.uid,
        name: _nameController.text.trim(),
        type: _selectedType,
        description: _descriptionController.text.trim(),
        phone:
            '${AppConstants.phoneNumberPrefix}${_phoneController.text.trim()}',
        location: 'Riyadh, $neighborhood',
        city: 'Riyadh',
        neighborhood: neighborhood ?? 'Unknown',
        googleMapsLink: _googleMapsController.text.trim(),
        thumbnailUrl: _thumbnailUrl ?? '',
        carouselImages: _carouselUrls,
        priceRange: _selectedPriceRange,
        tags: _selectedTags,
        isVerified: false,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        businessHours: _businessHours,
        socialLinks: _socialLinks.isEmpty ? null : _socialLinks,
      );

      await _spotService.createSpot(spot);

      if (mounted) {
        context.go('/spot-management');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating spot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadThumbnail() async {
    try {
      final XFile? image = await _storageService.pickImage();
      if (image == null) return;

      setState(() => _isUploadingThumbnail = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final url = await _storageService.uploadImage(
        user.uid,
        image,
        folder: 'thumbnail',
      );

      setState(() => _thumbnailUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingThumbnail = false);
    }
  }

  Future<void> _pickAndUploadCarouselImages() async {
    try {
      final List<XFile> images = await _storageService.pickMultiImage();
      if (images.isEmpty) return;

      if (images.length + _carouselUrls.length >
          AppConstants.maxCarouselImages) {
        throw Exception(
          'Maximum ${AppConstants.maxCarouselImages} images allowed',
        );
      }

      setState(() => _isUploadingCarousel = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final urls = await _storageService.uploadMultipleImages(
        user.uid,
        images,
        'carousel',
      );

      setState(() {
        _carouselUrls.addAll(urls);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingCarousel = false);
    }
  }

  void _removeCarouselImage(int index) {
    setState(() {
      _carouselUrls.removeAt(index);
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register Your Spot',
          style: GoogleFonts.ibmPlexSans(),
        ),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            OnboardingStepIndicator(
              currentStep: _currentStep,
              totalSteps: _steps.length,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildImagesStep();
      case 3:
        return _buildDetailsStep();
      case 4:
        return _buildHoursStep();
      case 5:
        return _buildFinalStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start with the essential details about your spot',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Spot Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.store),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              if (value.length < AppConstants.minNameLength) {
                return 'Name must be at least ${AppConstants.minNameLength} characters';
              }
              if (value.length > AppConstants.maxNameLength) {
                return 'Name must be less than ${AppConstants.maxNameLength} characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.phone),
              prefixText: '${AppConstants.phoneNumberPrefix} ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a phone number';
              }
              if (value.length != AppConstants.phoneNumberLength) {
                return 'Phone number must be ${AppConstants.phoneNumberLength} digits';
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Please enter only numbers';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Spot Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: SpotService.spotTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                  // Reset tags when type changes
                  _selectedTags = [];
                });
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPriceRange,
            decoration: InputDecoration(
              labelText: 'Price Range',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            items: SpotService.priceRanges.map((range) {
              return DropdownMenuItem(
                value: range,
                child: Text(
                  '$range - ${SpotService.priceRangeDescriptions[range]}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPriceRange = value;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _currentStep == _steps.length - 1 ? _handleSubmit : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _currentStep == _steps.length - 1 ? 'Submit' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help customers find your spot easily',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _googleMapsController,
            decoration: InputDecoration(
              labelText: 'Google Maps Link',
              helperText: 'Paste your Google Maps location link here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.map),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a Google Maps link';
              }
              if (!_spotService.isValidGoogleMapsLink(value)) {
                return 'Please enter a valid Google Maps link';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedNeighborhood,
            decoration: InputDecoration(
              labelText: 'Neighborhood',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_city),
            ),
            items: AppConstants.riyadhNeighborhoods.map((neighborhood) {
              return DropdownMenuItem(
                value: neighborhood,
                child: Text(neighborhood),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedNeighborhood = value;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Images',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos to showcase your spot',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ImageUploadCard(
            imageUrl: _thumbnailUrl,
            title: 'Add Thumbnail',
            description: 'This will be the main image for your spot',
            onTap: _pickAndUploadThumbnail,
            isUploading: _isUploadingThumbnail,
            onDelete: _thumbnailUrl != null
                ? () => setState(() => _thumbnailUrl = null)
                : null,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gallery Images',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _isUploadingCarousel
                    ? null
                    : _carouselUrls.length >= AppConstants.maxCarouselImages
                        ? null
                        : _pickAndUploadCarouselImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_carouselUrls.isEmpty)
            Center(
              child: Text(
                'No gallery images added yet',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _carouselUrls.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _carouselUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white),
                          onPressed: () => _removeCarouselImage(index),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _thumbnailUrl == null
                  ? null
                  : _carouselUrls.isEmpty
                      ? null
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    final availableTags = SpotService.defaultTagsByType[_selectedType] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide more information about your spot',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              if (value.length < AppConstants.minDescriptionLength) {
                return 'Description must be at least ${AppConstants.minDescriptionLength} characters';
              }
              if (value.length > AppConstants.maxDescriptionLength) {
                return 'Description must be less than ${AppConstants.maxDescriptionLength} characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Tags',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Social Media',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...AppConstants.socialPlatforms.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: entry.value,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(_getSocialIcon(entry.key)),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    _socialLinks.remove(entry.key);
                  } else {
                    _socialLinks[entry.key] = value;
                  }
                },
              ),
            );
          }).toList(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  // Continuation of spot_onboarding_screen.dart
// Add these remaining methods to the _SpotOnboardingScreenState class

  IconData _getSocialIcon(String platform) {
    switch (platform) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'twitter':
        return Icons.chat_bubble_outline;
      case 'snapchat':
        return Icons.chat_outlined;
      case 'tiktok':
        return Icons.music_video_outlined;
      case 'website':
        return Icons.language_outlined;
      default:
        return Icons.link;
    }
  }

  Widget _buildHoursStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Hours',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your operating hours for each day',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          BusinessHoursPicker(
            initialHours: _businessHours,
            onChanged: (hours) {
              setState(() {
                _businessHours = hours;
              });
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your spot information before submitting',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          _buildReviewSection(
            'Basic Information',
            [
              _buildReviewItem('Name', _nameController.text),
              _buildReviewItem('Phone',
                  '${AppConstants.phoneNumberPrefix} ${_phoneController.text}'),
              _buildReviewItem('Type', _selectedType),
              _buildReviewItem('Price Range',
                  '$_selectedPriceRange - ${SpotService.priceRangeDescriptions[_selectedPriceRange]}'),
            ],
          ),
          _buildReviewSection(
            'Location',
            [
              _buildReviewItem('Neighborhood', _selectedNeighborhood),
              _buildReviewItem('Maps Link', _googleMapsController.text),
            ],
          ),
          _buildReviewSection(
            'Images',
            [
              _buildReviewItem('Thumbnail', 'Added'),
              _buildReviewItem(
                  'Gallery Images', '${_carouselUrls.length} images'),
            ],
          ),
          _buildReviewSection(
            'Details',
            [
              _buildReviewItem('Description', _descriptionController.text),
              _buildReviewItem('Tags', _selectedTags.join(', ')),
              if (_socialLinks.isNotEmpty)
                _buildReviewItem(
                    'Social Links', '${_socialLinks.length} platforms'),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[700]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[900]),
                    const SizedBox(width: 8),
                    Text(
                      'Important Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your spot will be reviewed by our team before being published. '
                  'This typically takes 1-2 business days.',
                  style: TextStyle(
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit Spot'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...items,
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
