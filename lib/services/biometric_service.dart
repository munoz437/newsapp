import 'package:local_auth/local_auth.dart';

class BiometricService {

  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    return await auth.canCheckBiometrics;
  }

  Future<bool> authenticate() async {

    try {
      return await auth.authenticate(
        localizedReason: 'Autentícate para ingresar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}