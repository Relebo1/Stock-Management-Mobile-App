import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Salted PBKDF2 hashes are used for local prototype accounts.
class PasswordHasher {
  static const _iterations = 600000;
  static const _algorithmName = 'pbkdf2-sha256';
  static final _pbkdf2 = Pbkdf2.hmacSha256(iterations: _iterations, bits: 256);

  static Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final key = await _pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
    final digest = await key.extractBytes();
    return [_algorithmName, '$_iterations', base64UrlEncode(salt), base64UrlEncode(digest)].join(r'$');
  }

  static Future<bool> verify(String password, String encoded) async {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _algorithmName) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1 || iterations > 1000000) return false;
    try {
      final salt = base64Url.decode(base64Url.normalize(parts[2]));
      final expected = base64Url.decode(base64Url.normalize(parts[3]));
      final algorithm = Pbkdf2.hmacSha256(iterations: iterations, bits: expected.length * 8);
      final key = await algorithm.deriveKeyFromPassword(password: password, nonce: salt);
      final actual = await key.extractBytes();
      if (actual.length != expected.length) return false;
      var difference = 0;
      for (var i = 0; i < actual.length; i++) {
        difference |= actual[i] ^ expected[i];
      }
      return difference == 0;
    } on FormatException {
      return false;
    }
  }
}
