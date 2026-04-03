import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.blue.shade900,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Términos de Servicio',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Aceptación de Términos'),
            _buildSectionContent(
              'Al acceder y utilizar JobSwipe AI, aceptas estar vinculado por estos términos y condiciones. Si no estás de acuerdo con cualquier parte de estos términos, no debes utilizar nuestro servicio.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('2. Uso del Servicio'),
            _buildSectionContent(
              'Accedes a JobSwipe AI bajo la condición de que no usarás la plataforma para propósitos ilegales o no autorizados. Eres responsable de mantener la confidencialidad de tu cuenta y contraseña.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('3. Cuenta de Usuario'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint(
                  'Debes proporcionar información precisa y completa al registrarte',
                ),
                _buildBulletPoint(
                  'Eres responsable de toda la actividad en tu cuenta',
                ),
                _buildBulletPoint(
                  'Debes notificarnos inmediatamente de cualquier acceso no autorizado',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('4. Propiedad Intelectual'),
            _buildSectionContent(
              'Todo el contenido en JobSwipe AI, incluyendo textos, gráficos, logos y software, es propiedad de JobSwipe o sus proveedores de contenido y está protegido por leyes de derechos de autor.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('5. Limitación de Responsabilidad'),
            _buildSectionContent(
              'JobSwipe AI se proporciona "tal cual" sin garantías de ningún tipo. No somos responsables por daños directos, indirectos, incidentales o consecuentes derivados del uso de nuestro servicio.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('6. Modificaciones'),
            _buildSectionContent(
              'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios serán efectivos inmediatamente después de su publicación.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('7. Contacto'),
            _buildSectionContent(
              'Si tienes preguntas sobre estos términos, contáctanos en support@jobswipe.com',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'Última actualización: Marzo 2026',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.blue.shade900,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      textAlign: TextAlign.justify,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 14,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
