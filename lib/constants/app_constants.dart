class AppConstants {
  // Riyadh Neighborhoods
  static const List<String> riyadhNeighborhoods = [
    'Al Olaya',
    'Al Muruj',
    'Al Wurud',
    'Al Nakheel',
    'Al Rahmaniyah',
    'Al Yasmin',
    'Al Malqa',
    'Al Narjis',
    'Al Sahafah',
    'An Nuzhah',
    'Al Mughrizat',
    'Al Hazm',
    'Al Hamra',
    'Al Falah',
    'Al Manar',
    'King Abdullah District',
    'Al Masif',
    'Al Sulaimaniyah',
    'Al Raid',
    'Other',
  ];

  // Business Hours Template
  static const Map<String, Map<String, String>> defaultBusinessHours = {
    'Sunday': {'open': '09:00', 'close': '22:00'},
    'Monday': {'open': '09:00', 'close': '22:00'},
    'Tuesday': {'open': '09:00', 'close': '22:00'},
    'Wednesday': {'open': '09:00', 'close': '22:00'},
    'Thursday': {'open': '09:00', 'close': '22:00'},
    'Friday': {'open': '16:00', 'close': '23:00'},
    'Saturday': {'open': '09:00', 'close': '22:00'},
  };

  // Social Media Platforms
  static const Map<String, String> socialPlatforms = {
    'instagram': 'Instagram',
    'twitter': 'Twitter',
    'snapchat': 'Snapchat',
    'tiktok': 'TikTok',
    'website': 'Website',
  };

  // Image Upload Constraints
  static const int maxThumbnailSize = 2 * 1024 * 1024; // 2MB
  static const int maxCarouselImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxCarouselImages = 10;

  // Validation
  static const int minDescriptionLength = 50;
  static const int maxDescriptionLength = 800;
  static const int minNameLength = 3;
  static const int maxNameLength = 50;
  static const int phoneNumberLength = 9;

  // Phone Number Format
  static const String phoneNumberPrefix = '+966';
}
