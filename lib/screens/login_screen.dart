import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogleLogin,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.work_outline_rounded,
                  size: 72,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 20),
                Text(
                  'JobSwipe',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Encuentra oportunidades con un solo inicio de sesión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue.shade600, fontSize: 15),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onGoogleLogin,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      isLoading ? 'Iniciando...' : 'Iniciar sesión con Google',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (errorMessage != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
