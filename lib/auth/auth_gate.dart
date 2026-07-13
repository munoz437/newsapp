import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/news_feed_screen.dart';
import '../screens/verification_pending_screen.dart';

/// AuthGate listens to Firebase auth state changes and redirects the user
/// to the appropriate screen:
///  - No user → LoginScreen
///  - User exists but email not verified → VerificationPendingScreen
///  - User fully authenticated → NewsFeedScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while the stream is initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final user = snapshot.data;

        if (user == null) {
          // Not signed in
          return const LoginScreen();
        }

        // Google sign-in users are always considered verified by Firebase,
        // so check emailVerified only for email/password accounts.
        final isEmailProvider = user.providerData
            .any((p) => p.providerId == 'password');

        if (isEmailProvider && !user.emailVerified) {
          return const VerificationPendingScreen();
        }

        // Fully authenticated and verified
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
                  colors: [colors.primary, colors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.newspaper_rounded,
                  size: 44, color: colors.onPrimary),
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
