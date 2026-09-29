import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/app_user.dart';
import '../../data/models/user_role.dart';
import '../../data/models/business.dart';

/// Possible states for the authentication flow.
enum AuthStatus {
  idle,
  loading,
  verificationEmailSent,
  passwordResetSent,
  passwordUpdated,
  accountDeleted,
  businessCreated,
  success,
  error,
}

/// ViewModel managing authentication and user state.
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.idle;
  AuthStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  String? _pendingInvitation;
  String? get pendingInvitation => _pendingInvitation;

  Business? _userBusiness;
  Business? get userBusiness => _userBusiness;

  AuthViewModel() {
    checkCurrentUser();
  }

  void checkCurrentUser() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _status = AuthStatus.idle;
      _currentUser = null;
      notifyListeners();
      return;
    }

    firebaseUser.reload().then((_) {
      if (firebaseUser.emailVerified) {
        _fetchUserData(firebaseUser.uid);
      } else {
        _status = AuthStatus.idle;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError('Per favore compila tutti i campi');
      return;
    }
    _setLoading();
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user != null) {
        if (user.emailVerified) {
          await _fetchUserData(user.uid);
        } else {
          _setError('Email non verificata. Controlla la tua posta.');
        }
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Errore durante il login');
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String confirmPassword,
    UserRole role,
  ) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _setError('Per favore compila tutti i campi');
      return;
    }
    if (password != confirmPassword) {
      _setError('Le password non coincidono');
      return;
    }
    _setLoading();
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = result.user;
      if (firebaseUser != null) {
        await firebaseUser.sendEmailVerification();
        final appUser = AppUser(
          id: firebaseUser.uid,
          name: name.trim(),
          email: email.trim(),
          role: role,
        );
        await _db
            .collection('users')
            .doc(firebaseUser.uid)
            .set(appUser.toFirestore());
        _status = AuthStatus.verificationEmailSent;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Errore durante la registrazione');
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      _setError('Per favore inserisci la tua email');
      return;
    }
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _status = AuthStatus.passwordResetSent;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Errore reset password');
    }
  }

  Future<void> createBusiness(
    String name,
    String category,
    String description,
    String address,
  ) async {
    final managerId = _auth.currentUser?.uid;
    if (managerId == null) return;
    _setLoading();
    try {
      final businessId = const Uuid().v4();
      final business = Business(
        id: businessId,
        name: name,
        category: category,
        description: description,
        address: address,
        managerId: managerId,
        providerIds: [managerId],
      );
      await _db
          .collection('businesses')
          .doc(businessId)
          .set(business.toFirestore());
      await _db
          .collection('users')
          .doc(managerId)
          .update({'businessId': businessId});
      _userBusiness = business;
      _status = AuthStatus.businessCreated;
      notifyListeners();
      _refreshUserDataSilent(managerId);
    } catch (e) {
      _setError('Errore creazione azienda: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      _setError('La password deve essere di almeno 6 caratteri');
      return;
    }
    _setLoading();
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      _status = AuthStatus.passwordUpdated;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Errore aggiornamento password');
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _setLoading();
    try {
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
      _currentUser = null;
      _status = AuthStatus.accountDeleted;
      notifyListeners();
    } catch (e) {
      _setError('Errore eliminazione account');
    }
  }

  Future<void> acceptInvitation() async {
    final businessId = _pendingInvitation;
    final userId = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email;
    if (businessId == null || userId == null || email == null) return;

    try {
      await _db.runTransaction((transaction) async {
        final userRef = _db.collection('users').doc(userId);
        final businessRef = _db.collection('businesses').doc(businessId);
        final inviteRef = _db.collection('invitations').doc(email);

        final businessDoc = await transaction.get(businessRef);
        final business = Business.fromFirestore(businessDoc);
        final updatedProviders = [...business.providerIds, userId];

        transaction.update(userRef, {'businessId': businessId});
        transaction.update(businessRef, {'providerIds': updatedProviders});
        transaction.delete(inviteRef);
      });
      _pendingInvitation = null;
      await _fetchUserData(userId);
    } catch (e) {
      _setError('Errore accettazione invito');
    }
  }

  void declineInvitation() {
    final email = _auth.currentUser?.email;
    if (email == null) return;
    _db.collection('invitations').doc(email).delete();
    _pendingInvitation = null;
    notifyListeners();
  }

  void logout() {
    _auth.signOut();
    _currentUser = null;
    _userBusiness = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  void resetState() {
    final user = _currentUser;
    if (user != null) {
      _status = AuthStatus.success;
    } else {
      _status = AuthStatus.idle;
    }
    _errorMessage = '';
    notifyListeners();
  }

  // --- Private helpers ---

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    _setLoading();
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
        _status = AuthStatus.success;
        notifyListeners();
        if (_currentUser!.businessId != null) {
          _fetchBusinessData(_currentUser!.businessId!);
        }
        if (_currentUser!.role == UserRole.provider &&
            _currentUser!.businessId == null) {
          _checkForInvitations(_currentUser!.email);
        }
      } else {
        _setError('Utente non trovato nel database');
      }
    } catch (e) {
      _setError('Errore recupero dati: $e');
    }
  }

  Future<void> _refreshUserDataSilent(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
        _status = AuthStatus.success;
        notifyListeners();
        if (_currentUser!.businessId != null) {
          _fetchBusinessData(_currentUser!.businessId!);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchBusinessData(String businessId) async {
    try {
      final doc = await _db.collection('businesses').doc(businessId).get();
      if (doc.exists) {
        _userBusiness = Business.fromFirestore(doc);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _checkForInvitations(String email) async {
    try {
      final doc = await _db.collection('invitations').doc(email).get();
      if (doc.exists && doc.data()?['status'] == 'pending') {
        _pendingInvitation = doc.data()?['businessId'] as String?;
        notifyListeners();
      }
    } catch (_) {}
  }
}
