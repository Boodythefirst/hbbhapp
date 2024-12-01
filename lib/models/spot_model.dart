import 'package:cloud_firestore/cloud_firestore.dart';

class SpotModel {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String description;
  final String phone;
  final String location;
  final String city;
  final String neighborhood;
  final String googleMapsLink;
  final String thumbnailUrl;
  final List<String> carouselImages;
  final String priceRange;
  final double rating;
  final List<String> tags;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, Map<String, dynamic>>
      businessHours; // Changed from Map<String, Map<String, String>>
  final Map<String, dynamic>? socialLinks;

  SpotModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.description,
    required this.phone,
    required this.location,
    required this.city,
    required this.neighborhood,
    required this.googleMapsLink,
    required this.thumbnailUrl,
    required this.carouselImages,
    required this.priceRange,
    this.rating = 0.0,
    required this.tags,
    this.isVerified = false,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    required this.businessHours,
    this.socialLinks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'type': type,
      'description': description,
      'phone': phone,
      'location': location,
      'city': city,
      'neighborhood': neighborhood,
      'googleMapsLink': googleMapsLink,
      'thumbnailUrl': thumbnailUrl,
      'carouselImages': carouselImages,
      'priceRange': priceRange,
      'rating': rating,
      'tags': tags,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'businessHours': businessHours,
      'socialLinks': socialLinks,
    };
  }

  factory SpotModel.fromMap(Map<String, dynamic> map, String id) {
    // Convert the nested businessHours map
    final rawHours = map['businessHours'] as Map<String, dynamic>;
    final Map<String, Map<String, dynamic>> convertedHours = {};

    rawHours.forEach((day, hours) {
      if (hours is Map) {
        convertedHours[day] = Map<String, dynamic>.from(hours);
      }
    });

    return SpotModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      city: map['city'] ?? '',
      neighborhood: map['neighborhood'] ?? '',
      googleMapsLink: map['googleMapsLink'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      carouselImages: List<String>.from(map['carouselImages'] ?? []),
      priceRange: map['priceRange'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      businessHours: convertedHours,
      socialLinks: map['socialLinks'] as Map<String, dynamic>?,
    );
  }

  SpotModel copyWith({
    String? name,
    String? type,
    String? description,
    String? phone,
    String? location,
    String? city,
    String? neighborhood,
    String? googleMapsLink,
    String? thumbnailUrl,
    List<String>? carouselImages,
    String? priceRange,
    double? rating,
    List<String>? tags,
    bool? isVerified,
    bool? isActive,
    Map<String, Map<String, dynamic>>? businessHours,
    Map<String, dynamic>? socialLinks,
  }) {
    return SpotModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      carouselImages: carouselImages ?? this.carouselImages,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      businessHours: businessHours ?? this.businessHours,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}
