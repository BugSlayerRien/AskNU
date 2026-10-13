import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import 'audit_service.dart';
import 'analytics_store_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  AuthService._(this._auth);

  static final AuthService instance = AuthService._(FirebaseAuth.instance);

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: Attempting sign in for: $email');
      }
      
      // 1. Sign in with Firebase Auth
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (kDebugMode) {
        debugPrint('DEBUG: Firebase Auth sign in successful');
      }
      
      // 2. Log analytics
      await AnalyticsService.instance.logSignIn(method: 'email');
      await AnalyticsStoreService.instance.incrementDaily('signIns');
      
      // 3. Ensure user document exists
      final user = cred.user;
      if (user != null) {
        await _ensureUserDocument(user);
        await AuditService.instance.logAudit(action: 'sign_in', targetUserId: user.uid);
        await AuditService.instance.logUserActivity(
          type: 'sign_in',
          description: 'User signed in',
          userId: user.uid,
        );
        if (kDebugMode) {
          debugPrint('DEBUG: User document ensured for: ${user.uid}');
        }
      }
      
      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Sign in error: $e');
      }
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password, {
    String? firstName,
    String? lastName,
    String? studentId,
    String? department,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: Attempting sign up for: $email');
      }
      
      // 1. Create user in Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (kDebugMode) {
        debugPrint('DEBUG: Firebase Auth sign up successful');
      }
      
      // 2. Log analytics
      await AnalyticsService.instance.logSignUp(method: 'email');
      await AnalyticsStoreService.instance.incrementDaily('signUps');
      
      // 3. Create user document in Firestore
      final user = cred.user;
      if (user != null) {
        final userData = {
          'email': email,
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'fullName': '${firstName ?? ''} ${lastName ?? ''}'.trim(),
          'studentId': studentId ?? '',
          'department': department ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'notifications': true,
          'questionsAsked': 0,
          'faqsViewed': 0,
          'isEmailVerified': false,
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);
        await AuditService.instance.logAudit(action: 'sign_up', targetUserId: user.uid);
        await AuditService.instance.logUserActivity(
          type: 'sign_up',
          description: 'User signed up',
          userId: user.uid,
        );
            
        if (kDebugMode) {
          debugPrint('DEBUG: User document created for: ${user.uid}');
        }
      }
      
      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Sign up error: $e');
      }
      rethrow;
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: Ensuring user document for: ${user.uid}');
      }
      
      final col = FirebaseFirestore.instance.collection('users');
      final doc = col.doc(user.uid);
      
      // Try to get the document first
      final snapshot = await doc.get();
      
      if (!snapshot.exists) {
        if (kDebugMode) {
          debugPrint('DEBUG: User document does not exist, creating...');
        }
        // Create minimal user document
        await doc.set({
          'email': user.email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isEmailVerified': user.emailVerified,
        });
        if (kDebugMode) {
          debugPrint('DEBUG: User document created successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('DEBUG: User document exists, updating last login...');
        }
        // Update last login
        await doc.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'isEmailVerified': user.emailVerified,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Error ensuring user document: $e');
      }
      // Don't throw - we don't want sign in to fail if Firestore has issues
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (user != null) {
      await AuditService.instance.logAudit(action: 'sign_out', targetUserId: user.uid);
      await AuditService.instance.logUserActivity(
        type: 'sign_out',
        description: 'User signed out',
        userId: user.uid,
      );
    }
    await AnalyticsStoreService.instance.incrementDaily('signOuts');
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final cred = await _auth.signInWithCredential(credential);
    await AnalyticsService.instance.logSignIn(method: 'google');
    await AnalyticsStoreService.instance.incrementDaily('signIns');
    final user = cred.user;
    
    if (user != null) {
      // Create or update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'email': user.email,
            'firstName': googleUser.displayName?.split(' ').first ?? '',
            'lastName': googleUser.displayName?.split(' ').last ?? '',
            'fullName': googleUser.displayName ?? '',
            'photoURL': googleUser.photoUrl,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'notifications': true,
            'isEmailVerified': user.emailVerified,
          }, SetOptions(merge: true));
      await AuditService.instance.logAudit(action: 'sign_in_google', targetUserId: user.uid);
      await AuditService.instance.logUserActivity(
        type: 'sign_in_google',
        description: 'User signed in with Google',
        userId: user.uid,
      );
    }
    
    return user;
  }

  Future<Map<String, dynamic>?> getUserDocument() async {
    try {
      final u = _auth.currentUser;
      if (u == null) return null;
      
      if (kDebugMode) {
        debugPrint('DEBUG: Getting user document for: ${u.uid}');
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
          
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('DEBUG: User document does not exist for: ${u.uid}');
        }
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('DEBUG: User document retrieved successfully');
      }
      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Error getting user document: $e');
      }
      return null;
    }
  }

  Future<bool> isAdmin() async {
    try {
      final doc = await getUserDocument();
      if (doc == null) return false;
      
      final role = doc['role']?.toString().toLowerCase() ?? '';
      if (kDebugMode) {
        debugPrint('DEBUG: User role is: $role');
      }
      return role == 'admin';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Error checking admin status: $e');
      }
      return false;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final u = _auth.currentUser;
      if (u == null) throw Exception('No user logged in');
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .set({
            ...updates,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Error updating user profile: $e');
      }
      rethrow;
    }
  }

  Future<String?> getUserName() async {
    try {
      final doc = await getUserDocument();
      if (doc == null) return null;
      
      final fullName = doc['fullName']?.toString();
      final firstName = doc['firstName']?.toString();
      final email = doc['email']?.toString();
      
      if (fullName?.isNotEmpty == true) return fullName;
      if (firstName?.isNotEmpty == true) return firstName;
      if (email?.isNotEmpty == true) return email?.split('@').first;
      
      return 'Student';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Error getting user name: $e');
      }
      return null;
    }
  }

  // REMOVED: promoteToAdmin method - no longer needed
  // Admin roles are now set manually in Firestore Console
}