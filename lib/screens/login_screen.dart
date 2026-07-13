import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _emailNotVerified = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo electronico.';
      case 'wrong-password':
        return 'La contrasena es incorrecta.';
      case 'invalid-credential':
      case 'invalid-email':
        return 'Correo o contrasena invalidos. Revisa e intenta de nuevo.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intentalo de nuevo.';
      case 'network-request-failed':
        return 'Sin conexion a internet. Verifica tu red.';
      default:
        return e.message ?? 'Ocurrio un error inesperado.';
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _emailNotVerified = false;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _emailNotVerified = true;
          _errorMessage =
              'Tu correo aun no esta verificado. Revisa tu bandeja de entrada y haz clic en el enlace de verificacion.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } catch (_) {
      setState(() => _errorMessage = 'Error inesperado. Intentalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await cred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Correo de verificacion reenviado.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (_) {
      setState(
          () => _errorMessage = 'No se pudo reenviar el correo. Intentalo mas tarde.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

Future<void> _signInWithGoogle() async {
  setState(() {
    _loading = true;
    _errorMessage = null;
    _emailNotVerified = false;
  });

  try {
    // Obligatorio en google_sign_in 7.x
    await GoogleSignIn.instance.initialize();

    // Abre el selector de cuentas de Google
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    // Obtiene el token de Google
    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('Google no devolvió un ID Token.');
    }

    // Convierte el token de Google en una credencial de Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Inicia sesión en Firebase
    await FirebaseAuth.instance.signInWithCredential(credential);
  } on GoogleSignInException catch (e) {
    debugPrint('GoogleSignInException: ${e.code}');
    debugPrint('Detalles: $e');

    if (!mounted) return;

    setState(() {
      _errorMessage = 'Error de Google: ${e.code}. Revisa la consola.';
    });
  } on FirebaseAuthException catch (e) {
    debugPrint('FirebaseAuthException: ${e.code}');
    debugPrint('Mensaje: ${e.message}');

    if (!mounted) return;

    setState(() {
      _errorMessage = _friendlyError(e);
    });
  } catch (e, stackTrace) {
    debugPrint('Error inesperado en Google Sign-In: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    setState(() {
      _errorMessage = 'Error al iniciar con Google: $e';
    });
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    _buildLogo(context, colors),
                    const SizedBox(height: 40),
                    _buildFormCard(context, colors, isDark),
                    const SizedBox(height: 20),
                    _buildDivider(colors),
                    const SizedBox(height: 20),
                    _buildGoogleButton(context, colors),
                    const SizedBox(height: 24),
                    _buildRegisterLink(context, colors),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, ColorScheme colors) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.newspaper_rounded, size: 38, color: colors.onPrimary),
        ),
        const SizedBox(height: 20),
        Text(
          'InfoPulse',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colors.onSurface,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tu feed de noticias personalizado',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, ColorScheme colors, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest.withOpacity(0.5)
            : colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Iniciar sesion',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              context: context,
              controller: _emailController,
              label: 'Correo electronico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu correo';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                  return 'Formato invalido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              context: context,
              controller: _passwordController,
              label: 'Contrasena',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Ingresa tu contrasena' : null,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) _buildErrorBanner(context, colors),
            _buildPrimaryButton(
              context: context,
              label: 'Iniciar sesion',
              loading: _loading,
              onPressed: _signInWithEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, ColorScheme colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 18, color: colors.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                      color: colors.onErrorContainer, fontSize: 13),
                ),
              ),
            ],
          ),
          if (_emailNotVerified) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loading ? null : _resendVerification,
              child: Text(
                'Reenviar correo de verificacion',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: colors.onSurfaceVariant),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withOpacity(0.4),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;
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
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: colors.primary),
                )
              : Text(
                  label,
                  style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colors) {
    return Row(children: [
      Expanded(child: Divider(color: colors.outlineVariant)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('o continua con',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
      ),
      Expanded(child: Divider(color: colors.outlineVariant)),
    ]);
  }

  Widget _buildGoogleButton(BuildContext context, ColorScheme colors) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _loading ? null : _signInWithGoogle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleG(),
            const SizedBox(width: 12),
            Text('Continuar con Google',
                style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleG() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(children: [
        Center(
          child: Text(
            'G',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4285F4),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildRegisterLink(BuildContext context, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('No tienes cuenta?',
            style: TextStyle(color: colors.onSurfaceVariant)),
        TextButton(
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6)),
          onPressed: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const RegisterScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          child: Text('Registrate',
              style: TextStyle(
                  color: colors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}


