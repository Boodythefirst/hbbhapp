import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookmarksCollection = 'bookmarks';
  static const String _bookmarksKey = 'bookmarks';

  Future<List<String>> getBookmarks() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Get bookmarks from Firebase for authenticated users
        final doc = await _firestore
            .collection(_bookmarksCollection)
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          return List<String>.from(data?['spots'] ?? []);
        }
        return [];
      } else {
        // Fallback to SharedPreferences for guest users
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList(_bookmarksKey) ?? [];
      }
    } catch (e) {
      // Fallback to SharedPreferences on error
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_bookmarksKey) ?? [];
    }
  }

  Future<void> toggleBookmark(String spotId) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Handle Firebase bookmarks for authenticated users
        final docRef =
            _firestore.collection(_bookmarksCollection).doc(user.uid);
        final doc = await docRef.get();

        if (doc.exists) {
          final currentBookmarks =
              List<String>.from(doc.data()?['spots'] ?? []);
          if (currentBookmarks.contains(spotId)) {
            currentBookmarks.remove(spotId);
          } else {
            currentBookmarks.add(spotId);
          }
          await docRef.update({
            'spots': currentBookmarks,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await docRef.set({
            'spots': [spotId],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Handle local bookmarks for guest users
        final prefs = await SharedPreferences.getInstance();
        final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

        if (bookmarks.contains(spotId)) {
          bookmarks.remove(spotId);
        } else {
          bookmarks.add(spotId);
        }

        await prefs.setStringList(_bookmarksKey, bookmarks);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isBookmarked(String spotId) async {
    final bookmarks = await getBookmarks();
    return bookmarks.contains(spotId);
  }

  Future<List<Map<String, dynamic>>> getBookmarkedSpots(
      List<Map<String, dynamic>> allSpots) async {
    final bookmarkedIds = await getBookmarks();
    return allSpots
        .where((spot) => bookmarkedIds.contains(spot['id']))
        .toList();
  }

  // Method to migrate local bookmarks to Firebase when user signs in
  Future<void> migrateLocalBookmarks() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final localBookmarks = prefs.getStringList(_bookmarksKey) ?? [];

        if (localBookmarks.isNotEmpty) {
          final docRef =
              _firestore.collection(_bookmarksCollection).doc(user.uid);
          final doc = await docRef.get();

          if (doc.exists) {
            final currentBookmarks =
                List<String>.from(doc.data()?['spots'] ?? []);
            final mergedBookmarks =
                {...currentBookmarks, ...localBookmarks}.toList();
            await docRef.update({
              'spots': mergedBookmarks,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            await docRef.set({
              'spots': localBookmarks,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // Clear local bookmarks after migration
          await prefs.remove(_bookmarksKey);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
