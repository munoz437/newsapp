import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  bool _biometricsEnabled = false;
  bool _loadingBiometrics = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final isEnabled = await _storageService.getBiometricPreference();
    setState(() {
      _biometricsEnabled = isEnabled;
      _loadingBiometrics = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    setState(() {
      _loadingBiometrics = true;
    });
    
    // In a real app we might want to check if biometrics are available 
    // before allowing them to enable it, but relying on existing implementation
    await _storageService.saveBiometricPreference(value);
    
    setState(() {
      _biometricsEnabled = value;
      _loadingBiometrics = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Autenticación biométrica activada' : 'Autenticación biométrica desactivada'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Cambiar Contraseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.red.shade100,
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'ContraseÃ±a Actual',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva ContraseÃ±a',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setStateDialog(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final currentPassword = currentPasswordController.text.trim();
                            final newPassword = newPasswordController.text.trim();

                            if (currentPassword.isEmpty || newPassword.isEmpty) {
                              setStateDialog(() {
                                errorMessage = 'Por favor ingresa ambas contraseÃ±as.';
                                isLoading = false;
                              });
                              return;
                            }

                            if (newPassword.length < 6) {
                              setStateDialog(() {
                                errorMessage = 'La nueva contraseÃ±a debe tener al menos 6 caracteres.';
                                isLoading = false;
                              });
                              return;
                            }

                            // Reauthenticate
                            AuthCredential credential = EmailAuthProvider.credential(
                              email: currentUser.email!,
                              password: currentPassword,
                            );

                            await currentUser.reauthenticateWithCredential(credential);

                            // Update Password
                            await currentUser.updatePassword(newPassword);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ContraseÃ±a actualizada exitosamente')),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setStateDialog(() {
                              if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
                                errorMessage = 'La contraseÃ±a actual es incorrecta.';
                              } else {
                                errorMessage = 'Error: ${e.message}';
                              }
                              isLoading = false;
                            });
                          } catch (e) {
                            setStateDialog(() {
                              errorMessage = 'OcurriÃ³ un error inesperado.';
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Section
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user?.email?.isNotEmpty == true
                          ? user!.email!.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 32,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Usuario',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Sin correo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Configuración',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Biometrics
          SwitchListTile(
            title: const Text('Desbloqueo biométrico'),
            subtitle: const Text('Usa tu huella o rostro para entrar'),
            secondary: const Icon(Icons.fingerprint_rounded),
            value: _biometricsEnabled,
            onChanged: _loadingBiometrics ? null : _toggleBiometrics,
          ),
          const Divider(),

          // Change Password
          ListTile(
            leading: const Icon(Icons.lock_reset_rounded),
            title: const Text('Cambiar Contraseña'),
            onTap: _showChangePasswordDialog,
          ),
          const Divider(),

          // Favorites
          ListTile(
            leading: const Icon(Icons.favorite_rounded),
            title: const Text('Mis Favoritos'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          const Divider(),

          const SizedBox(height: 24),

          // Sign out
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                // Return to previous screen (the gate handles redirect)
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              backgroundColor: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
