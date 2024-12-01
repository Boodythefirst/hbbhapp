import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:hbbh/constants/app_constants.dart';
import 'package:hbbh/models/spot_model.dart';
import 'package:hbbh/services/spot_service.dart';
import 'package:hbbh/services/storage_service.dart';
import 'package:hbbh/widgets/spot/business_hours_picker.dart';
import 'package:hbbh/widgets/spot/image_upload_card.dart';

class SpotEditScreen extends StatefulWidget {
  final SpotModel spot;

  const SpotEditScreen({
    Key? key,
    required this.spot,
  }) : super(key: key);

  @override
  _SpotEditScreenState createState() => _SpotEditScreenState();
}

class _SpotEditScreenState extends State<SpotEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _spotService = SpotService();
  final _storageService = StorageService();

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isUploadingThumbnail = false;
  bool _isUploadingCarousel = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _googleMapsController;

  late String _selectedType;
  late String _selectedPriceRange;
  late String _selectedNeighborhood;
  late List<String> _selectedTags;
  late Map<String, Map<String, String>> _businessHours;
  late Map<String, String> _socialLinks;

  String? _thumbnailUrl;
  List<String> _carouselUrls = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize text controllers with current spot data
    _nameController = TextEditingController(text: widget.spot.name);
    _phoneController = TextEditingController(
      text: widget.spot.phone.replaceAll(AppConstants.phoneNumberPrefix, ''),
    );
    _descriptionController =
        TextEditingController(text: widget.spot.description);
    _googleMapsController =
        TextEditingController(text: widget.spot.googleMapsLink);

    // Initialize other fields
    _selectedType = widget.spot.type;
    _selectedPriceRange = widget.spot.priceRange;
    _selectedNeighborhood = widget.spot.neighborhood;
    _selectedTags = List.from(widget.spot.tags);

    // Convert business hours properly
    _businessHours = widget.spot.businessHours.map(
      (key, value) => MapEntry(
        key,
        Map<String, String>.from({
          'open': value['open']?.toString() ?? '00:00',
          'close': value['close']?.toString() ?? '00:00',
        }),
      ),
    );

    // Handle social links safely
    _socialLinks = widget.spot.socialLinks != null
        ? Map<String, String>.from(widget.spot.socialLinks!
            .map((key, value) => MapEntry(key, value.toString())))
        : {};

    // Initialize images
    _thumbnailUrl = widget.spot.thumbnailUrl;
    _carouselUrls = List.from(widget.spot.carouselImages);

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _googleMapsController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
                'You have unsaved changes. Are you sure you want to leave?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? neighborhood;
      try {
        neighborhood = await _spotService.extractNeighborhoodFromGoogleMapsLink(
          _googleMapsController.text,
        );
      } catch (e) {
        // If extraction fails, use selected neighborhood
        neighborhood = _selectedNeighborhood;
      }

      final updatedSpot = widget.spot.copyWith(
        name: _nameController.text.trim(),
        type: _selectedType,
        description: _descriptionController.text.trim(),
        phone:
            '${AppConstants.phoneNumberPrefix}${_phoneController.text.trim()}',
        location: 'Riyadh, $neighborhood',
        neighborhood: neighborhood,
        googleMapsLink: _googleMapsController.text.trim(),
        thumbnailUrl: _thumbnailUrl,
        carouselImages: _carouselUrls,
        priceRange: _selectedPriceRange,
        tags: _selectedTags,
        businessHours: _businessHours,
        socialLinks: _socialLinks.isEmpty ? null : _socialLinks,
      );

      await _spotService.updateSpot(updatedSpot);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Spot', style: GoogleFonts.ibmPlexSans()),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  tabs: const [
                    Tab(text: 'Basic Info'),
                    Tab(text: 'Location'),
                    Tab(text: 'Images'),
                    Tab(text: 'Additional'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBasicInfoTab(),
                      _buildLocationTab(),
                      _buildImagesTab(),
                      _buildAdditionalTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Continue adding these methods to the _SpotEditScreenState class

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  _selectedTags = []; // Reset tags when type changes
                  _hasChanges = true;
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
                  _hasChanges = true;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText: 'Tell customers about your spot',
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
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _googleMapsController,
            decoration: InputDecoration(
              labelText: 'Google Maps Link',
              helperText: 'Paste your Google Maps location link here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.map),
              suffixIcon: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () async {
                  final url = _googleMapsController.text;
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              ),
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
                  _hasChanges = true;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[900]),
                    const SizedBox(width: 8),
                    Text(
                      'How to get your Google Maps link',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Open Google Maps\n'
                  '2. Search for your location\n'
                  '3. Click "Share" or tap the location name\n'
                  '4. Copy the link and paste it here',
                  style: TextStyle(
                    color: Colors.blue[900],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thumbnail Image',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is the main image that will represent your spot',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ImageUploadCard(
            imageUrl: _thumbnailUrl,
            title: 'Add Thumbnail',
            description: 'Recommended size: 1200x800 pixels',
            onTap: _pickAndUploadThumbnail,
            isUploading: _isUploadingThumbnail,
            onDelete: _thumbnailUrl != null
                ? () => setState(() {
                      _thumbnailUrl = null;
                      _hasChanges = true;
                    })
                : null,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gallery Images',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_carouselUrls.length}/${AppConstants.maxCarouselImages} images',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No gallery images yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add images to showcase your spot',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableGridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _carouselUrls.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final url = _carouselUrls.removeAt(oldIndex);
                  _carouselUrls.insert(newIndex, url);
                  _hasChanges = true;
                });
              },
              itemBuilder: (context, index) {
                return Stack(
                  key: ValueKey(_carouselUrls[index]),
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
                          onPressed: () {
                            setState(() {
                              _carouselUrls.removeAt(index);
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Image ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Hours',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          BusinessHoursPicker(
            initialHours: _businessHours,
            onChanged: (hours) {
              setState(() {
                _businessHours = hours;
                _hasChanges = true;
              });
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tags',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedTags.length} selected',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpotService.defaultTagsByType[_selectedType]!.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                    _hasChanges = true;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'Social Media',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your social media links to help customers find you',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...AppConstants.socialPlatforms.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                initialValue: _socialLinks[entry.key],
                decoration: InputDecoration(
                  labelText: entry.value,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(_getSocialIcon(entry.key)),
                  helperText: _getSocialHelperText(entry.key),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      _socialLinks.remove(entry.key);
                    } else {
                      _socialLinks[entry.key] = value;
                    }
                    _hasChanges = true;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadCarouselImages() async {
    try {
      final List<XFile> images = await _storageService.pickMultiImage();
      if (images.isEmpty) return;

      if (images.length + _carouselUrls.length >
          AppConstants.maxCarouselImages) {
        throw Exception(
          'Maximum ${AppConstants.maxCarouselImages} images allowed. You can add ${AppConstants.maxCarouselImages - _carouselUrls.length} more.',
        );
      }

      setState(() => _isUploadingCarousel = true);

      final urls = await _storageService.uploadMultipleImages(
        widget.spot.id,
        images,
        'carousel',
      );

      setState(() {
        _carouselUrls.addAll(urls);
        _hasChanges = true;
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

  String _getSocialHelperText(String platform) {
    switch (platform) {
      case 'instagram':
        return 'e.g., instagram.com/yourspot';
      case 'twitter':
        return 'e.g., twitter.com/yourspot';
      case 'snapchat':
        return 'e.g., snapchat.com/add/yourspot';
      case 'tiktok':
        return 'e.g., tiktok.com/@yourspot';
      case 'website':
        return 'e.g., www.yourspot.com';
      default:
        return '';
    }
  }

  Future<void> _pickAndUploadThumbnail() async {
    try {
      final XFile? image = await _storageService.pickImage();
      if (image == null) return;

      setState(() => _isUploadingThumbnail = true);

      final url = await _storageService.uploadImage(
        widget.spot.id,
        image,
        folder: 'thumbnail',
      );

      setState(() {
        _thumbnailUrl = url;
        _hasChanges = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading thumbnail: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingThumbnail = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _googleMapsController.dispose();
    super.dispose();
  }
}
