import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _spotsCollection =
      FirebaseFirestore.instance.collection('spots');

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password, {
    bool isSpot = false,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify if the account type matches
      if (userCredential.user != null) {
        final userDoc =
            await _usersCollection.doc(userCredential.user!.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        if (userData?['isSpot'] != isSpot) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'wrong-account-type',
            message: isSpot
                ? 'This email is registered as a regular user account'
                : 'This email is registered as a spot account',
          );
        }

        // Update last login timestamp
        await _usersCollection.doc(userCredential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUserDocument({
    required String uid,
    required String email,
    String? name,
    bool isSpot = false,
  }) async {
    await _usersCollection.doc(uid).set({
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isGuest': false,
      'isSpot': isSpot,
      'onboardingCompleted': false,
    }, SetOptions(merge: true));

    // If it's a spot account, create an initial spot document
    if (isSpot) {
      await _spotsCollection.doc(uid).set({
        'ownerId': uid,
        'email': email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'isActive': false,
      });
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password, {
    bool isSpot = false,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await createUserDocument(
          uid: userCredential.user!.uid,
          email: email,
          isSpot: isSpot,
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Check if current user is a spot owner
  Future<bool> isSpotOwner() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _usersCollection.doc(user.uid).get();
        return (userDoc.data() as Map<String, dynamic>)['isSpot'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get spot data for spot owner
  Future<Map<String, dynamic>?> getSpotData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final spotDoc = await _spotsCollection.doc(user.uid).get();
        if (spotDoc.exists) {
          return spotDoc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserOnboardingData({
    required String name,
    required String ageGroup,
    required String visitFrequency,
    required List<String> interests,
  }) async {
    final User? user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    try {
      if (user != null) {
        await _usersCollection.doc(user.uid).update({
          'name': name,
          'ageGroup': ageGroup,
          'visitFrequency': visitFrequency,
          'interests': interests,
          'onboardingCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Handle guest user
        String? guestUserId = prefs.getString('guestUserId');

        if (guestUserId == null) {
          final guestDoc = await _usersCollection.add({
            'name': name,
            'ageGroup': ageGroup,
            'visitFrequency': visitFrequency,
            'interests': interests,
            'isGuest': true,
            'onboardingCompleted': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          guestUserId = guestDoc.id;
          await prefs.setString('guestUserId', guestUserId);
        } else {
          await _usersCollection.doc(guestUserId).update({
            'name': name,
            'ageGroup': ageGroup,
            'visitFrequency': visitFrequency,
            'interests': interests,
            'onboardingCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Fallback to local storage if Firestore fails
      await prefs.setString('user_name', name);
      await prefs.setString('user_age_group', ageGroup);
      await prefs.setString('user_visit_frequency', visitFrequency);
      await prefs.setStringList('user_interests', interests);
      await prefs.setBool('onboarding_completed', true);
      rethrow;
    }
  }

  Future<bool> isOnboardingCompleted() async {
    try {
      final User? user = _auth.currentUser;
      final prefs = await SharedPreferences.getInstance();

      if (user != null) {
        final userData = await _usersCollection.doc(user.uid).get();
        return (userData.data()
                as Map<String, dynamic>)['onboardingCompleted'] ??
            false;
      } else {
        final guestUserId = prefs.getString('guestUserId');
        if (guestUserId != null) {
          final guestData = await _usersCollection.doc(guestUserId).get();
          return (guestData.data()
                  as Map<String, dynamic>)['onboardingCompleted'] ??
              false;
        }
      }

      // Check local storage as fallback
      return prefs.getBool('onboarding_completed') ?? false;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_completed') ?? false;
    }
  }

  // Handle bookmarks
  Future<void> toggleBookmark(String spotId) async {
    final User? user = _auth.currentUser;
    final String userId;

    if (user != null) {
      userId = user.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('guestUserId') ?? '';
      if (userId.isEmpty) {
        throw Exception('No user ID found');
      }
    }

    final userDoc = await _usersCollection.doc(userId).get();
    final List<String> bookmarks = List<String>.from(
        (userDoc.data() as Map<String, dynamic>)['bookmarks'] ?? []);

    if (bookmarks.contains(spotId)) {
      bookmarks.remove(spotId);
    } else {
      bookmarks.add(spotId);
    }

    await _usersCollection.doc(userId).update({
      'bookmarks': bookmarks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user bookmarks
  Future<List<String>> getBookmarks() async {
    final User? user = _auth.currentUser;
    final String userId;

    if (user != null) {
      userId = user.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('guestUserId') ?? '';
      if (userId.isEmpty) return [];
    }
    final userDoc = await _usersCollection.doc(userId).get();
    return List<String>.from(
        (userDoc.data() as Map<String, dynamic>)['bookmarks'] ?? []);
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    final User? user = _auth.currentUser;
    final String userId;

    if (user != null) {
      userId = user.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('guestUserId') ?? '';
      if (userId.isEmpty) return;
    }

    await _usersCollection.doc(userId).update({
      'preferences': preferences,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user data
  Future<Map<String, dynamic>> getUserData() async {
    final User? user = _auth.currentUser;
    final String userId;

    if (user != null) {
      userId = user.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('guestUserId') ?? '';
      if (userId.isEmpty) return {};
    }

    final userDoc = await _usersCollection.doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  // Convert guest to authenticated user
  Future<void> convertGuestToUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final guestUserId = prefs.getString('guestUserId');

    if (guestUserId != null) {
      // Get existing guest data
      final guestDoc = await _usersCollection.doc(guestUserId).get();
      final guestData = guestDoc.data() as Map<String, dynamic>;

      // Create new authenticated user
      final UserCredential userCredential =
          await signUpWithEmailAndPassword(email, password);

      if (userCredential.user != null) {
        // Transfer guest data to new user document
        await _usersCollection.doc(userCredential.user!.uid).update({
          ...guestData,
          'email': email,
          'isGuest': false,
          'convertedFromGuestAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Delete guest document
        await _usersCollection.doc(guestUserId).delete();
        await prefs.remove('guestUserId');
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all local storage
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-account-type':
        return e.message ?? 'Invalid account type';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'weak-password':
        return 'Please choose a stronger password';
      default:
        return 'An error occurred. Please try again';
    }
  }
}
