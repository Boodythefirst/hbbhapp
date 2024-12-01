import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import 'package:hbbh/models/spot_model.dart';

class SpotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _spotsCollection =
      FirebaseFirestore.instance.collection('spots');

  // Get all spots with basic filtering
  Future<List<SpotModel>> getAllSpots({
    String? type,
    String? priceRange,
    List<String>? tags,
    bool activeOnly = true,
    bool verifiedOnly = true,
  }) async {
    try {
      Query query = _spotsCollection;

      // Apply basic filters
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      if (verifiedOnly) {
        query = query.where('isVerified', isEqualTo: true);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      if (priceRange != null) {
        query = query.where('priceRange', isEqualTo: priceRange);
      }

      final querySnapshot = await query.get();
      List<SpotModel> spots = querySnapshot.docs
          .map((doc) =>
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply tag filtering if needed (done in memory since Firestore doesn't support array contains any)
      if (tags != null && tags.isNotEmpty) {
        spots = spots.where((spot) {
          return spot.tags.any((tag) => tags.contains(tag));
        }).toList();
      }

      return spots;
    } catch (e) {
      rethrow;
    }
  }

  // Get featured spots
  Future<List<SpotModel>> getFeaturedSpots({int limit = 5}) async {
    try {
      final querySnapshot = await _spotsCollection
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get spots by rating
  Future<List<SpotModel>> getTopRatedSpots({int limit = 10}) async {
    try {
      final querySnapshot = await _spotsCollection
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get spots by price range
  Future<List<SpotModel>> getSpotsByPriceRange(
      {required String priceRange, int limit = 10}) async {
    try {
      final querySnapshot = await _spotsCollection
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .where('priceRange', isEqualTo: priceRange)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get spots by type (category)
  Future<List<SpotModel>> getSpotsByType(String type, {int limit = 10}) async {
    try {
      final querySnapshot = await _spotsCollection
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get nearby spots (based on neighborhood)
  Future<List<SpotModel>> getNearbySpots(
      {required String neighborhood, int limit = 10}) async {
    try {
      final querySnapshot = await _spotsCollection
          .where('neighborhood', isEqualTo: neighborhood)
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Search spots by name or tags
  Future<List<SpotModel>> searchSpots(String query) async {
    try {
      // Get all active and verified spots first
      final querySnapshot = await _spotsCollection
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      final spots = querySnapshot.docs
          .map((doc) =>
              SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter in memory for more flexible search
      final lowercaseQuery = query.toLowerCase();
      return spots.where((spot) {
        return spot.name.toLowerCase().contains(lowercaseQuery) ||
            spot.tags
                .any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
            spot.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get spot details
  Future<SpotModel> getSpotDetails(String spotId) async {
    try {
      final doc = await _spotsCollection.doc(spotId).get();
      if (!doc.exists) {
        throw Exception('Spot not found');
      }
      return SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  // Get current user's spot (for business owners)
  Future<SpotModel?> getCurrentUserSpot() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final doc = await _spotsCollection.doc(user.uid).get();
      if (!doc.exists) {
        return null;
      }
      return SpotModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  // Create new spot
  Future<void> createSpot(SpotModel spot) async {
    try {
      await _spotsCollection.doc(spot.id).set(spot.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update spot
  Future<void> updateSpot(SpotModel spot) async {
    try {
      await _spotsCollection.doc(spot.id).update(spot.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update spot status
  Future<void> updateSpotStatus({
    required String spotId,
    bool? isActive,
    bool? isVerified,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isActive != null) updates['isActive'] = isActive;
      if (isVerified != null) updates['isVerified'] = isVerified;

      await _spotsCollection.doc(spotId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete spot
  Future<void> deleteSpot(String spotId) async {
    try {
      await _spotsCollection.doc(spotId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Stream of all spots (combining Firestore and local data)
  Stream<List<Map<String, dynamic>>> spotsStream() async* {
    try {
      // Get local spots data
      final String response =
          await rootBundle.loadString('assets/spots_data.json');
      final localData = await json.decode(response) as Map<String, dynamic>;
      final List<Map<String, dynamic>> localSpots =
          List<Map<String, dynamic>>.from((localData['spots'] as List)
              .map((spot) => Map<String, dynamic>.from(spot)));

      // Create a stream controller for combining data
      final controller = StreamController<List<Map<String, dynamic>>>();

      // Subscribe to Firestore updates
      final firestoreSubscription = _spotsCollection
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        final List<Map<String, dynamic>> firestoreSpots =
            snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Ensure ID is included
          return data;
        }).toList();

        // Combine both sources and emit
        controller.add([...localSpots, ...firestoreSpots]);
      });

      // Clean up subscription when the stream is cancelled
      yield* controller.stream.transform(
        StreamTransformer.fromHandlers(
          handleDone: (sink) {
            firestoreSubscription.cancel();
            controller.close();
          },
        ),
      );
    } catch (e) {
      print('Error in spotsStream: $e');
      yield [];
    }
  }

  // A method to directly get all spots (both local and Firestore)
  Future<List<Map<String, dynamic>>> getAllSpotsOneTime() async {
    try {
      // Get local spots
      final String response =
          await rootBundle.loadString('assets/spots_data.json');
      final localData = await json.decode(response) as Map<String, dynamic>;
      final List<Map<String, dynamic>> localSpots =
          List<Map<String, dynamic>>.from((localData['spots'] as List)
              .map((spot) => Map<String, dynamic>.from(spot)));

      // Get Firestore spots
      final querySnapshot = await _spotsCollection
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> firestoreSpots =
          querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Combine and return
      return [...localSpots, ...firestoreSpots];
    } catch (e) {
      print('Error in getAllSpotsOneTime: $e');
      return [];
    }
  }

  // Get spot reviews
  Future<List<Map<String, dynamic>>> getSpotReviews(String spotId) async {
    try {
      final spotDoc = await _spotsCollection.doc(spotId).get();
      final spotData = spotDoc.data() as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(spotData['reviews'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to extract neighborhood from Google Maps link
  Future<String?> extractNeighborhoodFromGoogleMapsLink(String mapsLink) async {
    try {
      if (mapsLink.contains('goo.gl')) {
        return null;
      }

      final uri = Uri.parse(mapsLink);
      final String query = uri.queryParameters['q'] ??
          uri.queryParameters['query'] ??
          uri.queryParameters['location'] ??
          uri.fragment;

      if (query.isEmpty) {
        return null;
      }

      final List<String> parts = query.split(',');
      if (parts.length >= 2) {
        final String neighborhood = parts[1].trim();
        return neighborhood;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Validate Google Maps link
  bool isValidGoogleMapsLink(String link) {
    try {
      final uri = Uri.parse(link.trim());
      final validDomains = [
        'maps.google.com',
        'maps.app.goo.gl',
        'goo.gl',
        'maps.goo.gl',
        'maps.app.goo.gl',
        'www.google.com/maps'
      ];

      return validDomains.any((domain) =>
          uri.host.contains(domain) || uri.host.endsWith('google.com'));
    } catch (e) {
      return false;
    }
  }

  // Constants
  static const List<String> spotTypes = [
    'Cafe',
    'Restaurant',
    'Shopping',
    'Entertainment',
  ];

  static const List<String> priceRanges = [
    '\$',
    '\$\$',
    '\$\$\$',
    '\$\$\$\$',
  ];

  static const Map<String, String> priceRangeDescriptions = {
    '\$': 'Budget-friendly',
    '\$\$': 'Moderate',
    '\$\$\$': 'High-end',
    '\$\$\$\$': 'Luxury',
  };

  static const Map<String, List<String>> defaultTagsByType = {
    'Cafe': [
      'Coffee',
      'Breakfast',
      'Cozy',
      'Specialty Coffee',
      'Pastries',
      'Study-friendly'
    ],
    'Restaurant': [
      'Fine Dining',
      'Casual',
      'Family-friendly',
      'Romantic',
      'Local Cuisine',
      'International'
    ],
    'Shopping': [
      'Luxury',
      'Fashion',
      'Electronics',
      'Local Brands',
      'Souvenirs',
      'Mall'
    ],
    'Entertainment': [
      'Family-friendly',
      'Movies',
      'Arcade',
      'Sports',
      'Cultural',
      'Live Events'
    ],
  };
}
