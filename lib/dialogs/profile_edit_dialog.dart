import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../config/theme.dart';

/// Diálogo para editar datos del perfil
class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _companyNameController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _descriptionController =
        TextEditingController(text: widget.profile.description);
    _locationController =
        TextEditingController(text: widget.profile.location ?? '');
    _companyNameController =
        TextEditingController(text: widget.profile.companyName ?? '');
    _websiteController =
        TextEditingController(text: widget.profile.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCandidateProfile =
        widget.profile.userType == UserType.candidate;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: JobSwipeTheme.primaryIndigo.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: JobSwipeTheme.primaryIndigo,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    controller: _nameController,
                    label: isCandidateProfile ? 'Nombre completo' : 'Nombre de empresa',
                    hint: isCandidateProfile
                        ? 'Ej. Juan Pérez'
                        : 'Ej. Tech Company Inc',
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _descriptionController,
                    label: 'Descripción',
                    hint: 'Cuéntanos sobre ti',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  if (isCandidateProfile)
                    _buildField(
                      controller: _locationController,
                      label: 'Ubicación',
                      hint: 'Ej. Bogotá, Colombia',
                    )
                  else ...[
                    _buildField(
                      controller: _companyNameController,
                      label: 'Nombre de empresa',
                      hint: 'Ej. Tech Company Inc',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _websiteController,
                      label: 'Sitio web',
                      hint: 'Ej. www.techcompany.com',
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Retornar datos editados
                            Navigator.pop(context, {
                              'name': _nameController.text,
                              'description':
                                  _descriptionController.text,
                              'location': isCandidateProfile
                                  ? _locationController.text
                                  : null,
                              'companyName': !isCandidateProfile
                                  ? _companyNameController.text
                                  : null,
                              'website': !isCandidateProfile
                                  ? _websiteController.text
                                  : null,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JobSwipeTheme.primaryIndigo,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: JobSwipeTheme.primaryIndigo,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}
