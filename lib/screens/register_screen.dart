import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'verification_pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya esta registrado. Inicia sesion o usa otro correo.';
      case 'invalid-email':
        return 'El formato del correo electronico es invalido.';
      case 'weak-password':
        return 'La contrasena es demasiado debil. Usa al menos 8 caracteres.';
      case 'operation-not-allowed':
        return 'El registro con correo no esta habilitado. Contacta soporte.';
      case 'network-request-failed':
        return 'Sin conexion a internet. Verifica tu red.';
      default:
        return e.message ?? 'Ocurrio un error inesperado.';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() =>
          _errorMessage = 'Debes aceptar los terminos y condiciones para continuar.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      await cred.user?.sendEmailVerification();
      // Sign out so AuthGate shows VerificationPendingScreen via the route,
      // but we navigate explicitly here because the user just registered.
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const VerificationPendingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } catch (_) {
      setState(() => _errorMessage = 'Error inesperado. Intentalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    _buildHeader(context, colors),
                    const SizedBox(height: 32),
                    _buildFormCard(context, colors, isDark),
                    const SizedBox(height: 20),
                    _buildLoginLink(context, colors),
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

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.person_add_outlined,
              size: 32, color: colors.onPrimary),
        ),
        const SizedBox(height: 16),
        Text(
          'Crear cuenta',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colors.onSurface,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Completa los datos para registrarte',
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
            // Name
            _field(
              ctx: context,
              ctrl: _nameCtrl,
              label: 'Nombre completo',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 14),

            // Email
            _field(
              ctx: context,
              ctrl: _emailCtrl,
              label: 'Correo electronico',
              icon: Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu correo';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                  return 'Formato invalido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            _field(
              ctx: context,
              ctrl: _passCtrl,
              label: 'Contrasena (min. 8 caracteres)',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePass,
              suffix: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una contrasena';
                if (v.length < 8)
                  return 'Minimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Confirm password
            _field(
              ctx: context,
              ctrl: _confirmCtrl,
              label: 'Confirmar contrasena',
              icon: Icons.lock_reset_outlined,
              obscure: _obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) =>
                  v != _passCtrl.text ? 'Las contrasenas no coinciden' : null,
            ),
            const SizedBox(height: 18),

            // Terms checkbox
            _buildTermsCheckbox(context, colors),

            const SizedBox(height: 18),

            // Error banner
            if (_errorMessage != null) _buildErrorBanner(context, colors),

            // Register button
            _buildPrimaryButton(
              context: context,
              label: 'Crear cuenta',
              loading: _loading,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox(BuildContext context, ColorScheme colors) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              activeColor: colors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style:
                    TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                children: const [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Terminos y Condiciones',
                    style: TextStyle(
                      color: Color(0xFF5C6BC0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Politica de Privacidad',
                    style: TextStyle(
                      color: Color(0xFF5C6BC0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(
                    color: colors.onErrorContainer, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required BuildContext ctx,
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? type,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final colors = Theme.of(ctx).colorScheme;
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: colors.onSurfaceVariant),
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              : Text(label,
                  style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Ya tienes cuenta?',
            style: TextStyle(color: colors.onSurfaceVariant)),
        TextButton(
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Inicia sesion',
              style: TextStyle(
                  color: colors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
