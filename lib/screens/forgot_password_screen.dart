import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _loading = true;
      _message = null;
      _isError = false;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      // Siempre mostramos éxito genérico
      setState(() {
        _message = 'Si el correo existe, recibirás un enlace de recuperación.';
        _isError = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isError = true;
        if (e.code == 'invalid-email') {
          _message = 'El formato del correo es inválido.';
        } else {
          // Para no revelar si existe o no, o si está deshabilitado, podemos seguir 
          // mostrando el mensaje genérico o un error general.
          // El requerimiento dice: "mostrando siempre un mensaje genérico de éxito sin importar si el correo está registrado o no... maneja también errores de formato de email inválido"
          _message = 'Si el correo existe, recibirás un enlace de recuperación.';
          _isError = false; 
        }
      });
    } catch (_) {
      setState(() {
        _isError = true;
        _message = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.lock_reset_rounded, size: 80, color: colors.primary),
            const SizedBox(height: 24),
            Text(
              '¿Olvidaste tu contraseña?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ingresa tu correo electrónico y te enviaremos un enlace para restablecerla.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
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
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined, color: colors.onSurfaceVariant),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest.withOpacity(0.4),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
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
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu correo';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return 'Formato inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_message != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isError ? colors.errorContainer : colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isError ? Icons.error_outline : Icons.info_outline,
                              size: 20,
                              color: _isError ? colors.onErrorContainer : colors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: _isError ? colors.onErrorContainer : colors.onPrimaryContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _loading
                              ? null
                              : LinearGradient(
                                  colors: [colors.primary, colors.tertiary],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          borderRadius: BorderRadius.circular(14),
                          color: _loading ? colors.surfaceContainerHighest : null,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loading ? null : _resetPassword,
                          child: _loading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colors.primary,
                                  ),
                                )
                              : Text(
                                  'Enviar enlace',
                                  style: TextStyle(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
