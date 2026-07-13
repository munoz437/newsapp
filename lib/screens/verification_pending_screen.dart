import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends State<VerificationPendingScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _isResending = false;
  String? _message;
  bool _messageIsError = false;
  Timer? _autoCheckTimer;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-check every 5 seconds
    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerification(silent: true),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (!silent) setState(() => _isChecking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final verified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (verified) {
        // AuthGate will react to authStateChanges and push NewsFeedScreen.
        // Force a sign-out + sign-in cycle so stream fires, or just sign out:
        // Actually, reload() triggers authStateChanges on some versions.
        // We can also manually trigger a state rebuild by calling setState.
        // The cleanest way: sign out and back in to trigger the stream.
        // But we don't have the password, so just reload triggers the stream.
        if (!mounted) return;
        _setMessage('Correo verificado correctamente. Ingresando...', false);
      } else if (!silent) {
        _setMessage('Aun no verificado. Revisa tu bandeja de entrada.', true);
      }
    } catch (e) {
      if (!silent) _setMessage('Error al verificar. Intentalo de nuevo.', true);
    } finally {
      if (!silent && mounted) setState(() => _isChecking = false);
    }
  }

  void _setMessage(String msg, bool isError) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _messageIsError = isError;
    });
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _setMessage('Correo de verificacion reenviado correctamente.', false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        _setMessage(
            'Demasiados intentos. Espera unos minutos antes de reenviar.', true);
      } else {
        _setMessage('No se pudo reenviar el correo. Intentalo mas tarde.', true);
      }
    } catch (_) {
      _setMessage('Error inesperado. Intentalo de nuevo.', true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate stream will redirect to LoginScreen automatically.
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated envelope icon
              Center(
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primaryContainer,
                          colors.tertiaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 54,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              Text(
                'Revisa tu correo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enviamos un enlace de verificacion a:',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Haz clic en el enlace del correo para activar tu cuenta. Luego regresa aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontSize: 14),
              ),

              const SizedBox(height: 32),

              // Status message
              if (_message != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _messageIsError
                        ? colors.errorContainer
                        : colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _messageIsError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: _messageIsError
                            ? colors.onErrorContainer
                            : colors.onPrimaryContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _messageIsError
                                ? colors.onErrorContainer
                                : colors.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Check verification button
              _buildPrimaryButton(
                context: context,
                label: 'Ya verifique mi correo',
                icon: Icons.check_circle_outlined,
                loading: _isChecking,
                onPressed: () => _checkVerification(silent: false),
                colors: colors,
              ),

              const SizedBox(height: 12),

              // Resend button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: colors.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isResending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: colors.primary),
                      )
                    : Icon(Icons.refresh_rounded, color: colors.primary),
                label: Text(
                  'Reenviar correo',
                  style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.w600),
                ),
                onPressed: _isResending ? null : _resendEmail,
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Volver al inicio de sesion',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
    required ColorScheme colors,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(14),
          color: loading ? colors.surfaceContainerHighest : null,
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: loading ? null : onPressed,
          icon: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: colors.primary),
                )
              : Icon(icon, color: colors.onPrimary, size: 20),
          label: loading
              ? const SizedBox.shrink()
              : Text(label,
                  style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
        ),
      ),
    );
  }
}
