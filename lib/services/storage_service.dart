import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {

  final FlutterSecureStorage storage =
      const FlutterSecureStorage();


  Future<void> saveBiometricPreference(bool value) async {

    await storage.write(
      key: 'biometric_enabled',
      value: value.toString(),
    );

  }


  Future<bool> getBiometricPreference() async {

    String? value =
        await storage.read(key: 'biometric_enabled');

    return value == 'true';
  }
}