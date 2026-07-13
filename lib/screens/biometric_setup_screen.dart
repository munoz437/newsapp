import 'package:flutter/material.dart';

import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import 'news_feed_screen.dart';


class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}


class _BiometricSetupScreenState
    extends State<BiometricSetupScreen> {


  final BiometricService _biometricService =
      BiometricService();


  final StorageService _storageService =
      StorageService();


  bool _loading = false;



  Future<void> _activateBiometric() async {

    setState(() {
      _loading = true;
    });


    try {

      // Verificar si el dispositivo tiene biometría disponible
      final available =
          await _biometricService.isAvailable();


      if (!available) {

        _showMessage(
          'Este dispositivo no tiene biometría disponible.',
        );

        return;
      }



      // Solicitar huella o rostro
      final authenticated =
          await _biometricService.authenticate();



      if (authenticated) {


        // Guardar autorización del usuario
        await _storageService
            .saveBiometricPreference(true);



        if (!mounted) return;


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const NewsFeedScreen(),
          ),
        );


      } else {
        _showMessage(
          'No se pudo validar la biometría.',
        );
      }


    } catch (e) {

      _showMessage(
          'Error biometría: $e',
      );


    } finally {


      if (mounted) {

        setState(() {
          _loading = false;
        });

      }
    }
  }




  void _showMessage(String message) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(message),
      ),

    );
  }




  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(
        title:
            const Text('Configuración biométrica'),
      ),


      body: Center(

        child: Padding(

          padding:
              const EdgeInsets.all(24),


          child: Column(

            mainAxisAlignment:
                MainAxisAlignment.center,


            children: [


              const Icon(
                Icons.fingerprint,
                size: 90,
              ),


              const SizedBox(height: 30),



              const Text(

                'Activa el inicio de sesión biométrico',

                textAlign:
                    TextAlign.center,


                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),

              ),



              const SizedBox(height: 15),



              const Text(

                'Podrás ingresar más rápido usando tu huella o reconocimiento facial.',

                textAlign:
                    TextAlign.center,

              ),



              const SizedBox(height: 40),



              SizedBox(

                width: double.infinity,


                child: ElevatedButton(

                  onPressed:
                      _loading
                          ? null
                          : _activateBiometric,


                  child: _loading

                      ? const CircularProgressIndicator()

                      : const Text(
                          'Activar biometría',
                        ),

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}