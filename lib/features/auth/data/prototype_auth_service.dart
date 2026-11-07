import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import 'password_hasher.dart';

abstract interface class AuthService {
  Future<bool> signIn({required String identity, required String password});

  /// Returns an error message when registration fails, or null after success.
  Future<String?> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String businessName,
    required String businessType,
    required String password,
  });
}

class PrototypeAuthService implements AuthService {
  const PrototypeAuthService();

  static const _demoEmail = 'demo@stockmate.local';
  static const _browserUsersKey = 'stockmate.local_users.v1';

  @override
  Future<bool> signIn({required String identity, required String password}) async {
    final normalizedIdentity = identity.trim().toLowerCase();
    if (normalizedIdentity.isEmpty || password.isEmpty) return false;

    if (kIsWeb) {
      final users = await _browserUsers();
      if (normalizedIdentity == _demoEmail || normalizedIdentity == 'demo') return true;
      final matches = users.where((user) => user['email'] == normalizedIdentity || user['username'] == normalizedIdentity);
      if (matches.isEmpty) return false;
      return PasswordHasher.verify(password, matches.first['password_hash'] as String);
    }

    final db = await AppDatabase.instance.database;
    final matches = await db.query(
      'users',
      columns: ['password', 'status', 'email'],
      where: 'email = ? OR username = ?',
      whereArgs: [normalizedIdentity, normalizedIdentity],
      limit: 1,
    );
    if (matches.isEmpty || matches.first['status'] != 'ACTIVE') return false;
    if (matches.first['email'] == _demoEmail) return true;
    return PasswordHasher.verify(password, matches.first['password'] as String);
  }

  @override
  Future<String?> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String businessName,
    required String businessType,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();
    final passwordHash = await PasswordHasher.hash(password);

    if (kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      final users = await _browserUsers(preferences);
      if (users.any((user) => user['email'] == cleanEmail || user['username'] == cleanUsername || cleanEmail == _demoEmail || cleanUsername == 'demo')) {
        return 'An account already uses that email or username.';
      }
      users.add({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': phone.trim(),
        'password_hash': passwordHash,
        'business_name': businessName.trim(),
        'business_type': businessType,
      });
      await preferences.setString(_browserUsersKey, jsonEncode(users));
      return null;
    }

    final db = await AppDatabase.instance.database;
    try {
      await db.transaction((txn) async {
        final now = DateTime.now().toUtc().toIso8601String();
        final businessId = await txn.insert('businesses', {
          'name': businessName.trim(),
          'business_type': businessType,
          'email': cleanEmail,
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'currency': 'LSL',
          'status': 'ACTIVE',
          'created_at': now,
          'updated_at': now,
        });
        await txn.insert('business_settings', {'business_id': businessId});
        final roleId = await txn.insert('roles', {
          'business_id': businessId,
          'name': 'OWNER',
          'description': 'Business owner',
          'is_system': 0,
          'created_at': now,
        });
        final userId = await txn.insert('users', {
          'username': cleanUsername,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': cleanEmail,
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'password': passwordHash,
          'email_verified': 0,
          'status': 'ACTIVE',
          'created_at': now,
          'updated_at': now,
        });
        await txn.insert('business_users', {'business_id': businessId, 'user_id': userId, 'role_id': roleId, 'status': 'ACTIVE', 'joined_at': now});
        await txn.insert('locations', {'business_id': businessId, 'name': 'Main location', 'code': 'MAIN', 'status': 'ACTIVE', 'created_at': now});
      });
      return null;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) return 'An account already uses that email or username.';
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _browserUsers([SharedPreferences? preferences]) async {
    final store = preferences ?? await SharedPreferences.getInstance();
    final raw = store.getString(_browserUsersKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } on FormatException {
      return [];
    }
  }
}
