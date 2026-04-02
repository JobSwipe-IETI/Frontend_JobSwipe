import 'package:flutter/material.dart';
import '../controllers/user_provider.dart';
import '../dialogs/profile_edit_dialog.dart';
import 'profile_header.dart';
import 'switch_account_button.dart';

/// Perfil para usuario tipo EMPRESA
class CompanyProfileWidget extends StatefulWidget {
  final UserProvider userProvider;
  final VoidCallback onLogout;

  const CompanyProfileWidget({
    super.key,
    required this.userProvider,
    required this.onLogout,
  });

  @override
  State<CompanyProfileWidget> createState() => _CompanyProfileWidgetState();
}

class _CompanyProfileWidgetState extends State<CompanyProfileWidget> {
  bool _isSwitching = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProvider.currentUser;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del perfil (banner + logo)
          ProfileHeader(
            profile: profile,
            isEditable: true,
            onEditBanner: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualizar banner (mock)')),
              );
            },
            onEditProfile: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualizar logo (mock)')),
              );
            },
          ),
          const SizedBox(height: 60),

          // Información de la empresa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre de empresa
                Text(
                  profile.companyName ?? profile.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),

                // Website
                if (profile.website != null)
                  Row(
                    spacing: 6,
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      Text(
                        profile.website!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Descripción
                Text(
                  'Acerca de nosotros',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),

                // Sección de Vacantes publicadas
                _buildSectionCard(
                  icon: Icons.work_rounded,
                  title: 'Vacantes Publicadas',
                  subtitle: '5 vacantes activas',
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),

                // Sección de Aplicaciones recibidas
                _buildSectionCard(
                  icon: Icons.person_add_rounded,
                  title: 'Aplicantes',
                  subtitle: '32 candidatos interesados',
                  backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 28),

                // Botón de editar perfil
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => ProfileEditDialog(
                          profile: profile,
                        ),
                      );

                      if (result != null && mounted) {
                        widget.userProvider.updateProfile(
                          name: result['name'] ?? profile.name,
                          description: result['description'] ?? profile.description,
                          companyName: result['companyName'] ?? profile.companyName,
                          website: result['website'] ?? profile.website,
                          profileImageUrl: profile.profileImageUrl,
                          bannerImageUrl: profile.bannerImageUrl,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Perfil actualizado'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón principal para crear vacante
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Mostrar modal de crear vacante
                      _showCreateJobModal(context);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Crear Nueva Vacante',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón para cambiar a Candidato
                SwitchAccountTypeButton(
                  currentUserType: widget.userProvider.userType,
                  isLoading: _isSwitching,
                  onSwitch: () async {
                    setState(() => _isSwitching = true);
                    try {
                      await widget.userProvider.switchUserType();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cuenta cambiada a Candidato'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al cambiar cuenta: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSwitching = false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Botón de cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );
  }

  /// Muestra modal para crear nueva vacante
  void _showCreateJobModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return CreateJobFormWidget(
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

/// Widget para crear una nueva vacante
class CreateJobFormWidget extends StatefulWidget {
  final ScrollController scrollController;

  const CreateJobFormWidget({
    super.key,
    required this.scrollController,
  });

  @override
  State<CreateJobFormWidget> createState() => _CreateJobFormWidgetState();
}

class _CreateJobFormWidgetState extends State<CreateJobFormWidget> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Crear Nueva Vacante',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 24),

              // Campo: Título del puesto
              _buildTextField(
                label: 'Título del Puesto',
                controller: _titleController,
                hint: 'ej: Ingeniero Flutter Senior',
              ),
              const SizedBox(height: 16),

              // Campo: Descripción
              _buildTextField(
                label: 'Descripción',
                controller: _descriptionController,
                hint: 'Describe el rol y responsabilidades',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Campo: Salario
              _buildTextField(
                label: 'Rango Salarial',
                controller: _salaryController,
                hint: r'ej: $80k - $120k USD',
              ),
              const SizedBox(height: 16),

              // Campo: Ubicación
              _buildTextField(
                label: 'Ubicación',
                controller: _locationController,
                hint: 'ej: Remoto, Medellín, etc',
              ),
              const SizedBox(height: 28),

              // Botón Publicar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implementar envío del formulario
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Vacante publicada correctamente'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text(
                    'Publicar Vacante',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón Cancelar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
