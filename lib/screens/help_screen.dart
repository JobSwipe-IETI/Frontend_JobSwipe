import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  final List<FAQItem> _faqs = [
    FAQItem(
      question: '¿Cómo funciona el Match IA?',
      answer:
          'Nuestro algoritmo de IA analiza tu perfil profesional y tus preferencias para recomendarte las mejores oportunidades laborales adaptadas a tus habilidades y experiencia.',
    ),
    FAQItem(
      question: '¿Es seguro usar JobSwipe AI?',
      answer:
          'Sí, utilizamos encriptación de nivel bancario y medidas de seguridad avanzadas para proteger tu información personal y datos de cuenta.',
    ),
    FAQItem(
      question: '¿Cómo puedo cambiar mi contraseña?',
      answer:
          'Ve a Configuración > Seguridad > Cambiar Contraseña. Recibirás un código de verificación en tu email registrado.',
    ),
    FAQItem(
      question: '¿Qué significa el sistema de Swipe?',
      answer:
          'Puedes deslizar a la derecha para marcar empleos que te interesan, o a la izquierda para descartarlos. Los empleadores ven si te interesan sus ofertas.',
    ),
    FAQItem(
      question: '¿Puedo usar JobSwipe desde múltiples dispositivos?',
      answer:
          'Sí, puedes acceder a tu cuenta desde cualquier dispositivo iniciando sesión con tu email de Google.',
    ),
    FAQItem(
      question: '¿Hay una app de escritorio?',
      answer:
          'Actualmente, JobSwipe está optimizado para dispositivos móviles. Puedes acceder desde navegadores web en tu computadora.',
    ),
    FAQItem(
      question: '¿Cómo contacto con soporte?',
      answer:
          'Puedes contactarnos en support@jobswipe.com o a través del botón de ayuda dentro de la aplicación.',
    ),
    FAQItem(
      question: '¿Mis datos serán vendidos a terceros?',
      answer:
          'No, tu privacidad es nuestra prioridad. Consulta nuestra Política de Privacidad para más detalles sobre cómo manejamos tu información.',
    ),
  ];

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
          'Ayuda y Preguntas Frecuentes',
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
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar preguntas...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preguntas Frecuentes',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // FAQ List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final isExpanded = _expandedIndex == index;
                return _buildFAQItem(
                  index,
                  _faqs[index],
                  isExpanded,
                  () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            // Contact Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.cyan.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      Text(
                        '¿Necesitas más ayuda?',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contáctanos directamente si no encuentras la respuesta que buscas. Estamos aquí para ayudarte.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implementar contacto
                      },
                      icon: const Icon(Icons.mail_rounded),
                      label: const Text('Enviar Email al Soporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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

  Widget _buildFAQItem(
    int index,
    FAQItem item,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isExpanded ? Colors.blue.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded ? Colors.blue.shade300 : Colors.grey.shade300,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.answer,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
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

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
