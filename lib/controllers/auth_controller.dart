import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Login user and navigate to correct role screen
  Future<void> login(String email, String password, BuildContext context) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final roleSnap = await _dbRef.child('users/$uid/role').get();

      if (roleSnap.exists) {
        final role = roleSnap.value.toString();
        print('✅ Logged in as $role');

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver');
        } else {
          _showError(context, 'Unknown role: $role');
        }
      } else {
        _showError(context, 'Role not found. Please contact admin.');
      }
    } catch (e) {
      print('Login error: $e');
      _showError(context, 'Login failed: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Register new driver (only admin uses this)
  Future<String?> registerDriver(String email, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _dbRef.child('users/${cred.user!.uid}').set({
        'email': email,
        'role': 'driver',
      });

      return cred.user!.uid;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
