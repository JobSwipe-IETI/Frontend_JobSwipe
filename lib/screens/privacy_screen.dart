import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'Política de Privacidad',
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
            _buildSectionTitle('1. Información que Recopilamos'),
            _buildSectionContent(
              'Recopilamos información que proporcionas directamente y información recabada automáticamente al usar nuestro servicio.',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Información de cuenta (nombre, email, perfil profesional)'),
                _buildBulletPoint('Datos de uso (búsquedas, aplicaciones, interacciones)'),
                _buildBulletPoint('Información del dispositivo (tipo, SO, identificadores únicos)'),
                _buildBulletPoint('Logs de acceso (dirección IP, fecha y hora)'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('2. Cómo Usamos tu Información'),
            _buildSectionContent(
              'Utilizamos tu información para:',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Proporcionar y mejorar nuestros servicios'),
                _buildBulletPoint('Personalizar tu experiencia con IA'),
                _buildBulletPoint('Comunicarnos contigo sobre tu cuenta'),
                _buildBulletPoint('Complir con obligaciones legales'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('3. Seguridad de Datos'),
            _buildSectionContent(
              'Implementamos medidas de seguridad técnicas, administrativas y físicas para proteger tu información contra acceso, alteración, divulgación o destrucción no autorizados.',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Encriptación de datos en tránsito y en reposo'),
                _buildBulletPoint('Auditorías de seguridad regulares'),
                _buildBulletPoint('Control de acceso basado en roles'),
                _buildBulletPoint('Monitoreo 24/7 de amenazas'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('4. Compartición de Información'),
            _buildSectionContent(
              'No vendemos ni compartimos tu información personal con terceros, excepto:',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Cuando sea requerido por ley'),
                _buildBulletPoint('Con empleadores después de tu consentimiento'),
                _buildBulletPoint('Con proveedores de servicios bajo acuerdos de confidencialidad'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('5. Tus Derechos'),
            _buildSectionContent(
              'Tienes derecho a:',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Acceder a tu información personal'),
                _buildBulletPoint('Solicitar correcciones de datos inexactos'),
                _buildBulletPoint('Solicitar la eliminación de tu cuenta'),
                _buildBulletPoint('Opt-out de comunicaciones de marketing'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('6. Cookies y Tecnologías de Rastreo'),
            _buildSectionContent(
              'Utilizamos cookies y tecnologías similares para mejorar tu experiencia, entender cómo usas nuestro servicio y personalizar contenido.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('7. Retención de Datos'),
            _buildSectionContent(
              'Retenemos tu información personal solo el tiempo necesario para proporcionar nuestros servicios, a menos que la ley requiera un período de retención más largo.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('8. Cambios a esta Política'),
            _buildSectionContent(
              'Podemos actualizar esta política ocasionalmente. Te notificaremos de cambios significativos publicando la política actualizada en nuestro sitio web.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('9. Contacto'),
            _buildSectionContent(
              'Si tienes preguntas sobre esta política de privacidad, contacta a nuestro equipo de privacidad en privacy@jobswipe.com',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                spacing: 10,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu privacidad es importante',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Última actualización: Marzo 2026',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                color: Colors.green.shade600,
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
