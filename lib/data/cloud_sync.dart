import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Optional cloud backup using anonymous Firebase Auth + Firestore.
///
/// Layout:
///   users/{uid}                 -> { goalMl, cupMl, updatedAt }
///   users/{uid}/days/{yyyy-MM-dd} -> { ml, updatedAt }
///
/// Days written by the old glasses-based version hold `glasses` instead of
/// `ml`; [pullDays] converts them.
///
/// Firestore keeps an offline cache on Android, so writes made without a
/// connection are queued and sent later. Do NOT `await` writes in UI code.
class CloudSync {
  /// True once Firebase.initializeApp() succeeded (i.e. Firebase is configured).
  bool available = false;

  String? _uid;
  bool get signedIn => _uid != null;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      available = true;
    } catch (e) {
      debugPrint('Firebase not configured, cloud backup disabled: $e');
      available = false;
    }
  }

  Future<void> signIn() async {
    if (!available) return;
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
      _uid = user?.uid;
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      _uid = null;
    }
  }

  DocumentReference<Map<String, dynamic>> get _user =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  void pushDay(String key, int ml) {
    if (!signedIn) return;
    // set() without merge also drops an old `glasses` field.
    _user.collection('days').doc(key).set({
      'ml': ml,
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((Object e) => debugPrint('pushDay failed: $e'));
  }

  void pushSettings({required int goalMl, required int cupMl}) {
    if (!signedIn) return;
    _user.set({
      'goalMl': goalMl,
      'cupMl': cupMl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError(
        (Object e) => debugPrint('pushSettings failed: $e'));
  }

  /// Returns {yyyy-MM-dd: ml}, or an empty map if offline / failed.
  /// Old `glasses` days are converted at [legacyGlassMl] per glass.
  Future<Map<String, int>> pullDays({required int legacyGlassMl}) async {
    if (!signedIn) return {};
    try {
      final snap = await _user
          .collection('days')
          .get()
          .timeout(const Duration(seconds: 8));
      int ml(Map<String, dynamic> d) =>
          (d['ml'] as num?)?.toInt() ??
          ((d['glasses'] as num?)?.toInt() ?? 0) * legacyGlassMl;
      return {for (final d in snap.docs) d.id: ml(d.data())};
    } catch (e) {
      debugPrint('pullDays failed: $e');
      return {};
    }
  }

  /// Deletes this user's cloud data and the anonymous account itself.
  Future<void> deleteAllAndSignOut() async {
    if (!signedIn) return;
    try {
      final days = await _user.collection('days').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in days.docs) {
        batch.delete(d.reference);
      }
      batch.delete(_user);
      await batch.commit();
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      debugPrint('Cloud delete failed: $e');
    } finally {
      _uid = null;
    }
  }
}
