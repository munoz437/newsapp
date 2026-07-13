import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/login_screen.dart';
import '../screens/news_feed_screen.dart';
import '../screens/verification_pending_screen.dart';
import '../screens/biometric_setup_screen.dart';
import '../screens/biometric_unlock_screen.dart';

import '../services/storage_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final StorageService _storageService = StorageService();
  late final StreamSubscription<User?> _authSubscription;

  bool _checkingBiometric = true;
  bool _biometricConfigured = false;
  bool _biometricAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricConfiguration();

    // Resetear autenticación biométrica cuando se cierra sesión
    // y volver a verificar configuración cuando se inicia sesión.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        setState(() {
          _biometricAuthenticated = false;
        });
      } else {
        _checkBiometricConfiguration();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkBiometricConfiguration() async {
    setState(() {
      _checkingBiometric = true;
    });

    final enabled = await _storageService.getBiometricPreference();

    if (!mounted) return;

    setState(() {
      _biometricConfigured = enabled;
      _checkingBiometric = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        final isEmailProvider = user.providerData.any(
          (p) => p.providerId == 'password',
        );

        if (isEmailProvider && !user.emailVerified) {
          return const VerificationPendingScreen();
        }

        if (_checkingBiometric) {
          return const _SplashLoader();
        }

        if (!_biometricConfigured) {
          return const BiometricSetupScreen();
        }

        if (!_biometricAuthenticated) {
          return BiometricUnlockScreen(
            onAuthenticated: () {
              setState(() {
                _biometricAuthenticated = true;
              });
            },
          );
        }

        return const NewsFeedScreen();
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary,
                    colors.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.newspaper_rounded,
                size: 44,
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}