import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalAuthService {
  static const _fileName = 'users.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Map<String, dynamic>>> _readAll() async {
    final file = await _file();
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }

  static Future<void> _writeAll(List<Map<String, dynamic>> users) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(users));
  }

  /// Returns the user map if found, null otherwise.
  static Future<Map<String, dynamic>?> findByIdNumber(String idNumber) async {
    final users = await _readAll();
    try {
      return users.firstWhere((u) => u['id_number'] == idNumber);
    } catch (_) {
      return null;
    }
  }

  /// Creates a new user. Returns an error string on failure, null on success.
  static Future<String?> createUser({
    required String name,
    required String idNumber,
    required String phone,
    required List<String> alertContacts,
  }) async {
    final users = await _readAll();
    if (users.any((u) => u['id_number'] == idNumber)) {
      return 'A profile with this ID number already exists.';
    }
    users.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'id_number': idNumber,
      'phone': phone,
      'alert_contacts': alertContacts,
      'role': 'citizen',
      'created_at': DateTime.now().toIso8601String(),
    });
    await _writeAll(users);
    return null;
  }
}
