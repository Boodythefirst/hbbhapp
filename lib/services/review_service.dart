// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new review
  Future<ReviewModel> addReview({
    required String spotId,
    required String text,
    required double rating,
    required String userName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Must be logged in to leave a review');
      }

      // Create review document
      final reviewDoc = _firestore.collection('reviews').doc();
      final review = ReviewModel(
        id: reviewDoc.id,
        spotId: spotId,
        userId: user.uid,
        userName: userName,
        text: text,
        rating: rating,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await reviewDoc.set(review.toMap());

      // Update spot's average rating
      await _updateSpotRating(spotId);

      return review;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Get all reviews for a spot
  Stream<List<ReviewModel>> getSpotReviews(String spotId) {
    return _firestore
        .collection('reviews')
        .where('spotId', isEqualTo: spotId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Delete a review
  Future<void> deleteReview(String reviewId, String spotId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      await _updateSpotRating(spotId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Update spot's average rating
  Future<void> _updateSpotRating(String spotId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('spotId', isEqualTo: spotId)
          .get();

      if (reviews.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += doc.data()['rating'] as double;
      }

      final averageRating = totalRating / reviews.docs.length;
      await _firestore.collection('spots').doc(spotId).update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'reviewCount': reviews.docs.length,
      });
    } catch (e) {
      print('Error updating spot rating: $e');
    }
  }

  // Check if user has already reviewed this spot
  Future<bool> hasUserReviewed(String spotId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final review = await _firestore
          .collection('reviews')
          .where('spotId', isEqualTo: spotId)
          .where('userId', isEqualTo: user.uid)
          .get();

      return review.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
