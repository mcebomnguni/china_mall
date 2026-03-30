// ─────────────────────────────────────────────────────────────────────────────
//  services/application_service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';

class ApplicationService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  Future<void> createApplication(ServiceApplication app) async {
    _setLoading(true);
    try {
      await _db.collection('applications').doc(app.id).set(app.toMap());
    } catch (e) {
      print('Error creating application: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Upload file to Firebase Storage ───────────────────────────────────────
  Future<UploadedDocument?> uploadDocument({
    required String uid,
    required String applicationId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final type = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)
          ? 'image'
          : 'document';

      final ref = _storage.ref(
        'applications/$uid/$applicationId/$fileName',
      );

      late UploadTask task;
      if (kIsWeb) {
        // Web: use bytes
        task = ref.putData(
          await File(filePath).readAsBytes(),
          SettableMetadata(contentType: type == 'image' ? 'image/$ext' : 'application/pdf'),
        );
      } else {
        task = ref.putFile(File(filePath));
      }

      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();

      return UploadedDocument(
        name:       fileName,
        url:        url,
        type:       type,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ── Submit new application ────────────────────────────────────────────────
  Future<String?> submitApplication({
    required AppUser client,
    required String productCategoryId,
    required String productCategoryName,
    required String selectedProductId,
    required String selectedProductName,
    required List<UploadedDocument> documents,
  }) async {
    _setLoading(true);
    try {
      final id = const Uuid().v4();
      
      final app = ServiceApplication(
        id:                  id,
        clientUid:           client.uid,
        clientName:          client.fullName,
        clientEmail:         client.email,
        companyName:         client.companyName,
        productCategoryId:   productCategoryId,
        productCategoryName: productCategoryName,
        selectedProductId:   selectedProductId,
        selectedProductName: selectedProductName,
        documents:           documents,
        status:              ApplicationStatus.pendingReview,
        createdAt:           DateTime.now(),
        updatedAt:           DateTime.now(),
      );

      final appMap = app.toMap();
      
      await _db.collection('applications').doc(id).set(appMap);
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return 'Failed to submit application. Please try again.';
    }
  }

  // ── Stream client's own applications ──────────────────────────────────────
  Stream<List<ServiceApplication>> clientApplicationsStream(String uid) {
    return _db
        .collection('applications')
        .where('clientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          final apps = snap.docs
              .map((d) {
                final app = ServiceApplication.fromMap(d.data());
                return app;
              })
              .toList();
          return apps;
        });
  }

  // ── Stream ALL applications (admin) ──────────────────────────────────────
  Stream<List<ServiceApplication>> allApplicationsStream() {
    return _db
        .collection('applications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          final apps = snap.docs
              .map((d) {
                final app = ServiceApplication.fromMap(d.data());
                return app;
              })
              .toList();
          return apps;
        });
  }

  // ── Admin: update status ──────────────────────────────────────────────────
  Future<String?> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? adminNote,
    String? returnReason,
  }) async {
    _setLoading(true);
    try {
      final updates = <String, dynamic>{
        'status':    status.firestoreValue,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (adminNote    != null) updates['adminNote']    = adminNote;
      if (returnReason != null) updates['returnReason'] = returnReason;

      // Get application details before updating for notification
      final appDoc = await _db.collection('applications').doc(applicationId).get();
      if (appDoc.exists) {
        final app = ServiceApplication.fromMap(appDoc.data()!);
        
        // Update the application
        try {
          await _db.collection('applications').doc(applicationId).update({
            'status': status.firestoreValue,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          _setLoading(false);
          return null;
        } catch (e) {
          _setLoading(false);
          return 'Failed to update application.';
        }
        
        // Create notification for client
        await _createStatusNotification(app, status, adminNote, returnReason);
      }
      
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return 'Failed to update application.';
    }
  }

  // ── Create status notification for client ───────────────────────────────────
  Future<void> _createStatusNotification(
    ServiceApplication app,
    ApplicationStatus newStatus,
    String? adminNote,
    String? returnReason,
  ) async {
    try {
      final notification = {
        'id': const Uuid().v4(),
        'applicationId': app.id,
        'clientUid': app.clientUid,
        'clientEmail': app.clientEmail,
        'productName': app.selectedProductName,
        'previousStatus': app.status.firestoreValue,
        'newStatus': newStatus.firestoreValue,
        'adminNote': adminNote,
        'returnReason': returnReason,
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      };
      
      await _db.collection('notifications').doc(notification['id'] as String).set(notification);
    } catch (e) {
      // Error creating notification
    }
  }

  // ── Stream client notifications ───────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> clientNotificationsStream(String uid) {
    return _db
        .collection('notifications')
        .where('clientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── Mark notification as read ─────────────────────────────────────────────────
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      // Error marking notification as read
    }
  }

  // ── Get single application ─────────────────────────────────────────────────
  Future<ServiceApplication?> getApplication(String id) async {
    final doc = await _db.collection('applications').doc(id).get();
    if (!doc.exists) return null;
    return ServiceApplication.fromMap(doc.data()!);
  }

  // ── Admin: stream all users ───────────────────────────────────────────────
  Stream<List<AppUser>> allUsersStream() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppUser.fromMap(d.data()))
            .toList());
  }
}
