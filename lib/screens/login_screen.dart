import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../config/theme.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

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
      body: Stack(
        children: [
          // Gradient Header Background
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  JobSwipeTheme.primaryIndigo.withOpacity(0.7),
                  JobSwipeTheme.primaryBlue.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // White rounded content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: JobSwipeTheme.primaryIndigo.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLogoSection(),
                            const SizedBox(height: 32),
                            _buildTitleSection(),
                            const SizedBox(height: 16),
                            _buildDescriptionSection(),
                            const SizedBox(height: 40),
                            _buildGoogleLoginButton(context),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 20),
                              _buildErrorMessage(),
                            ],
                            const SizedBox(height: 32),
                            _buildTermsAndPrivacy(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: JobSwipeTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logoswipe.png',
        height: 140,
        width: 140,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: <Widget>[
        Text(
          'JobSwipe AI',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: JobSwipeTheme.primaryIndigo,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      children: <Widget>[
        Text(
          'Tu trabajo ideal te está esperando',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onGoogleLogin,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Image.asset(
                'assets/images/google_icon.png',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.login_rounded,
                  color: Colors.white,
                ),
              ),
        label: Text(
          isLoading ? 'Iniciando sesión...' : 'Continuar con Google',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: JobSwipeTheme.primaryIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JobSwipeTheme.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: JobSwipeTheme.errorRed.withOpacity(0.2),
        ),
      ),
      child: Row(
        spacing: 10,
        children: <Widget>[
          Icon(
            Icons.error_rounded,
            color: JobSwipeTheme.errorRed,
            size: 18,
          ),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: JobSwipeTheme.errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacy(BuildContext context) {
    return Column(
      spacing: 12,
      children: <Widget>[
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: Colors.grey.shade600,
            ),
            children: <TextSpan>[
              const TextSpan(text: 'Al continuar, aceptas nuestros '),
              TextSpan(
                text: 'Términos',
                style: TextStyle(
                  color: JobSwipeTheme.primaryIndigo,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _navigateToTerms(context),
              ),
              const TextSpan(text: ' y '),
              TextSpan(
                text: 'Privacidad',
                style: TextStyle(
                  color: JobSwipeTheme.primaryIndigo,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _navigateToPrivacy(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToTerms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsScreen(),
      ),
    );
  }

  void _navigateToPrivacy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyScreen(),
      ),
    );
  }
}
