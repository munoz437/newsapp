import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/biometric_service.dart';

class BiometricUnlockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const BiometricUnlockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  bool _authenticating = false;
  String? _errorMessage;

  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configuración de la animación de pulso para el icono de huella
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Intentar autenticación automática tras cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;

    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    try {
      final available = await _biometricService.isAvailable();
      if (!available) {
        setState(() {
          _errorMessage = 'La autenticación biométrica no está disponible en este dispositivo.';
        });
        return;
      }

      final success = await _biometricService.authenticate();
      if (success) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMessage = 'No se pudo verificar tu identidad. Intenta de nuevo.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _authenticating = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1F38), const Color(0xFF0F111E)]
                : [colors.primaryContainer.withOpacity(0.4), colors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Cabecera e Ilustración animada
                Text(
                  'Acceso Seguro',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Confirma tu identidad para continuar a InfoPulse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // Icono Interactivo con Animación de Ondas/Pulso
                GestureDetector(
                  onTap: _authenticating ? null : _authenticate,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _authenticating
                            ? CircularProgressIndicator(
                                strokeWidth: 4,
                                color: colors.onPrimary,
                              )
                            : Icon(
                                Icons.fingerprint_rounded,
                                size: 74,
                                color: colors.onPrimary,
                              ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Mensajes de error si los hay
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onErrorContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Botón de reintento si falló
                if (!_authenticating)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _authenticate,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text(
                        'Usar Biometría',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Botón para cerrar sesión
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
