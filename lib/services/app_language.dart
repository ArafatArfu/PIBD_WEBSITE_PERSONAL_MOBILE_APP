import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLanguage extends ChangeNotifier {
  static final instance = AppLanguage._();
  AppLanguage._();
  static const _key = 'app_language';
  final _storage = const FlutterSecureStorage();
  String _code = 'en';
  String get code => _code;
  bool get isBangla => _code == 'bn';
  String text(String en, String bn) => isBangla ? bn : en;
  Future<void> load() async {
    _code = await _storage.read(key: _key) ?? 'en';
    notifyListeners();
  }

  Future<void> setCode(String value) async {
    _code = value == 'bn' ? 'bn' : 'en';
    await _storage.write(key: _key, value: _code);
    notifyListeners();
  }
}
