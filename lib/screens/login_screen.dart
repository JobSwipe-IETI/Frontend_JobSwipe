import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../config/theme.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class LoginScreen extends StatefulWidget {
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
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final bool compact = screenHeight < 760 || screenWidth < 380;
    final double horizontalPadding = screenWidth > 900 ? 40 : 24;
    final double topSpacing = compact ? 28 : 44;
    final double bottomSpacing = compact ? 36 : 56;
    final double cardPadding = compact ? 34 : 44;
    final double cardRadius = compact ? 38 : 46;
    
    return Scaffold(
      body: Container(
        width: screenWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A1E5E),
              const Color(0xFF0D47A1),
              const Color(0xFF1565C0),
              const Color(0xFF1976D2),
              const Color(0xFF2196F3),
              const Color(0xFF42A5F5),
            ],
            stops: const [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            Positioned(
              top: -100,
              right: -100,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.01),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.cyan.withOpacity(0.08),
                          Colors.cyan.withOpacity(0.01),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - mediaQuery.padding.top - mediaQuery.padding.bottom,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topSpacing),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: compact ? 500 : 560,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(cardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.22),
                                      blurRadius: 54,
                                      spreadRadius: 12,
                                      offset: const Offset(0, 22),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF42A5F5).withOpacity(0.18),
                                      blurRadius: 30,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _buildLogoSection(),
                                      SizedBox(height: compact ? 28 : 36),
                                      _buildTitleSection(),
                                      SizedBox(height: compact ? 16 : 20),
                                      _buildDescriptionSection(),
                                      SizedBox(height: compact ? 32 : 44),
                                      _buildGoogleLoginButton(context),
                                      if (widget.errorMessage != null) ...[
                                        SizedBox(height: compact ? 20 : 26),
                                        _buildErrorMessage(),
                                      ],
                                      SizedBox(height: compact ? 26 : 34),
                                      _buildTermsAndPrivacy(context),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: bottomSpacing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Solo la sombra difuminada sin círculo sólido
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5E35B1).withOpacity(0.4),
                blurRadius: 100,
                spreadRadius: 40,
              ),
              BoxShadow(
                color: const Color(0xFF3F51B5).withOpacity(0.25),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
        // Logo en el centro
        Image.asset(
          'assets/images/logoswipe.png',
          height: 190,
          width: 190,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.business,
            size: 124,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              JobSwipeTheme.primaryIndigo,
              JobSwipeTheme.primaryBlue,
            ],
          ).createShader(bounds),
          child: const Text(
            'JobSwipe AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      children: [
        Text(
          'Tu trabajo ideal te está esperando',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JobSwipeTheme.primaryIndigo,
            JobSwipeTheme.primaryBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 8,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: JobSwipeTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onGoogleLogin,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                else
                  Image.asset(
                    'assets/images/google_icon.png',
                    height: 26,
                    width: 26,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    widget.isLoading
                        ? 'Iniciando sesión...'
                        : 'Continuar con Google',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JobSwipeTheme.errorRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JobSwipeTheme.errorRed.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(
            Icons.error_rounded,
            color: JobSwipeTheme.errorRed,
            size: 22,
          ),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: TextStyle(
                color: JobSwipeTheme.errorRed,
                fontSize: 14,
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
      spacing: 14,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(text: 'Al continuar, aceptas nuestros '),
              TextSpan(
                text: 'Términos',
                style: TextStyle(
                  color: JobSwipeTheme.primaryIndigo,
                  fontWeight: FontWeight.w800,
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
                  fontWeight: FontWeight.w800,
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
