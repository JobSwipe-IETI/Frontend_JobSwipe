import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../config/theme.dart';
import '../services/vacancy_service.dart';

class CreateVacancySection extends StatefulWidget {
  const CreateVacancySection({super.key});

  @override
  State<CreateVacancySection> createState() => _CreateVacancySectionState();
}

class _CreateVacancySectionState extends State<CreateVacancySection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final VacancyService _vacancyService = VacancyService();

  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _vacancySummaryController = TextEditingController();
  final TextEditingController _desiredSalaryController = TextEditingController();
  final TextEditingController _applicationDateController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _officialIdController = TextEditingController();
  final TextEditingController _otherDocumentsController = TextEditingController();
  final TextEditingController _academicLevelController = TextEditingController();
  final TextEditingController _institutionDetailsController = TextEditingController();
  final TextEditingController _previousEmploymentController = TextEditingController();
  final TextEditingController _responsibilitiesController = TextEditingController();
  final TextEditingController _salaryHistoryController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _officeFunctionsController = TextEditingController();
  final TextEditingController _softwareController = TextEditingController();
  final TextEditingController _softSkillsController = TextEditingController();
  final TextEditingController _referencesController = TextEditingController();
  final TextEditingController _referencesContactController = TextEditingController();
  final TextEditingController _openQuestionsController = TextEditingController();
  final TextEditingController _killerQuestionsController = TextEditingController();
  final TextEditingController _attachmentsController = TextEditingController();
  final TextEditingController _habitsGoalsController = TextEditingController();

  bool _isSubmitting = false;
  PlatformFile? _selectedAttachment;

  @override
  void dispose() {
    _positionController.dispose();
    _vacancySummaryController.dispose();
    _desiredSalaryController.dispose();
    _applicationDateController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _officialIdController.dispose();
    _otherDocumentsController.dispose();
    _academicLevelController.dispose();
    _institutionDetailsController.dispose();
    _previousEmploymentController.dispose();
    _responsibilitiesController.dispose();
    _salaryHistoryController.dispose();
    _languagesController.dispose();
    _officeFunctionsController.dispose();
    _softwareController.dispose();
    _softSkillsController.dispose();
    _referencesController.dispose();
    _referencesContactController.dispose();
    _openQuestionsController.dispose();
    _killerQuestionsController.dispose();
    _attachmentsController.dispose();
    _habitsGoalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: '1. Encabezado e Informacion de la Vacante',
              children: [
                _buildField(
                  controller: _positionController,
                  label: 'Puesto solicitado',
                  hint: 'Ej. Backend Developer Senior',
                ),
                _buildField(
                  controller: _desiredSalaryController,
                  label: 'Sueldo mensual deseado',
                  hint: 'Ej. 12000',
                  keyboardType: TextInputType.number,
                  validator: _salaryValidator,
                ),
                _buildDateField(
                  controller: _applicationDateController,
                  label: 'Fecha de la solicitud',
                  onTap: () => _pickDate(_applicationDateController),
                ),
                _buildField(
                  controller: _vacancySummaryController,
                  label: 'Resumen de la vacante',
                  hint: 'Describe contexto, objetivos y alcance del rol.',
                  maxLines: 3,
                ),
              ],
            ),
            _buildSectionCard(
              title: '2. Datos Personales y de Contacto',
              children: [
                _buildField(controller: _fullNameController, label: 'Nombre completo'),
                _buildField(
                  controller: _phoneController,
                  label: 'Telefono',
                  keyboardType: TextInputType.phone,
                ),
                _buildField(
                  controller: _emailController,
                  label: 'Correo electronico',
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                _buildField(
                  controller: _addressController,
                  label: 'Domicilio permanente',
                  maxLines: 2,
                ),
                _buildDateField(
                  controller: _birthDateController,
                  label: 'Fecha de nacimiento',
                  onTap: () => _pickDate(_birthDateController),
                ),
              ],
            ),
            _buildSectionCard(
              title: '3. Documentacion Legal e Identificacion',
              children: [
                _buildField(
                  controller: _officialIdController,
                  label: 'Identificaciones oficiales',
                  hint: 'CURP, RFC, NSS u otra identificacion valida.',
                ),
                _buildField(
                  controller: _otherDocumentsController,
                  label: 'Otros documentos',
                  hint: 'Licencia, pasaporte, cartilla militar, etc.',
                ),
              ],
            ),
            _buildSectionCard(
              title: '4. Formacion Academica',
              children: [
                _buildField(
                  controller: _academicLevelController,
                  label: 'Nivel academico',
                  hint: 'Primaria, secundaria, preparatoria, profesional o tecnica.',
                ),
                _buildField(
                  controller: _institutionDetailsController,
                  label: 'Detalles de la institucion',
                  maxLines: 2,
                ),
              ],
            ),
            _buildSectionCard(
              title: '5. Historial Laboral (Experiencia)',
              children: [
                _buildField(
                  controller: _previousEmploymentController,
                  label: 'Datos de empleos anteriores',
                  maxLines: 3,
                ),
                _buildField(
                  controller: _responsibilitiesController,
                  label: 'Responsabilidades',
                  maxLines: 3,
                ),
                _buildField(
                  controller: _salaryHistoryController,
                  label: 'Sueldos (inicial/final)',
                  maxLines: 2,
                ),
              ],
            ),
            _buildSectionCard(
              title: '6. Conocimientos y Habilidades',
              children: [
                _buildField(controller: _languagesController, label: 'Idiomas y nivel'),
                _buildField(controller: _officeFunctionsController, label: 'Funciones de oficina'),
                _buildField(controller: _softwareController, label: 'Software y maquinaria'),
                _buildField(controller: _softSkillsController, label: 'Habilidades blandas'),
              ],
            ),
            _buildSectionCard(
              title: '7. Referencias Personales y Laborales',
              children: [
                _buildField(
                  controller: _referencesController,
                  label: 'Contactos de referencia',
                  maxLines: 2,
                ),
                _buildField(
                  controller: _referencesContactController,
                  label: 'Telefono y tiempo de conocerse',
                ),
              ],
            ),
            _buildSectionCard(
              title: '8. Otros Apartados y Killer Questions',
              children: [
                _buildField(
                  controller: _openQuestionsController,
                  label: 'Preguntas abiertas',
                  maxLines: 3,
                ),
                _buildField(
                  controller: _killerQuestionsController,
                  label: 'Killer Questions',
                  maxLines: 2,
                ),
                _buildField(
                  controller: _attachmentsController,
                  label: 'Carga de documentos',
                  hint: 'Ruta local, URL o descripcion del CV/portafolio.',
                ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Seleccionar CV o Portafolio'),
                ),
                _buildField(
                  controller: _habitsGoalsController,
                  label: 'Habitos y metas',
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(
                  _isSubmitting ? 'Publicando...' : 'Publicar Vacante',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: JobSwipeTheme.primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crear Vacante',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6366F1),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa los 8 apartados para publicar una vacante completa.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ?? _requiredValidator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: JobSwipeTheme.primaryIndigo,
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: _requiredValidator,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_rounded),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: JobSwipeTheme.primaryIndigo,
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 80);
    final DateTime lastDate = DateTime(now.year + 10);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      final String formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      controller.text = formatted;
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final String? requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final bool isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    if (!isValid) {
      return 'Correo invalido';
    }
    return null;
  }

  String? _salaryValidator(String? value) {
    final String? requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final double? salary = double.tryParse(value!.trim());
    if (salary == null || salary < 0) {
      return 'Ingresa un monto valido';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double salary = double.parse(_desiredSalaryController.text.trim());

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ExtendedVacancyFormData payload = ExtendedVacancyFormData(
        positionRequested: _positionController.text.trim(),
        vacancySummary: _vacancySummaryController.text.trim(),
        desiredMonthlySalary: salary,
        applicationDate: _applicationDateController.text.trim(),
        candidateFullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        permanentAddress: _addressController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        officialIdentification: _officialIdController.text.trim(),
        otherDocuments: _otherDocumentsController.text.trim(),
        academicLevel: _academicLevelController.text.trim(),
        institutionDetails: _institutionDetailsController.text.trim(),
        previousEmploymentData: _previousEmploymentController.text.trim(),
        responsibilities: _responsibilitiesController.text.trim(),
        salaryHistory: _salaryHistoryController.text.trim(),
        languages: _languagesController.text.trim(),
        officeFunctions: _officeFunctionsController.text.trim(),
        softwareAndMachinery: _softwareController.text.trim(),
        softSkills: _softSkillsController.text.trim(),
        personalAndWorkReferences: _referencesController.text.trim(),
        referencesContactInfo: _referencesContactController.text.trim(),
        openQuestionsAnswers: _openQuestionsController.text.trim(),
        killerQuestionsAnswers: _killerQuestionsController.text.trim(),
        documentAttachments: _attachmentsController.text.trim(),
        habitsAndGoals: _habitsGoalsController.text.trim(),
      );

      await _vacancyService.createExtendedVacancy(
        payload,
        attachment: _selectedAttachment,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vacante creada exitosamente.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _formKey.currentState!.reset();
      _selectedAttachment = null;
      _clearControllers();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickAttachment() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo seleccionado.')),
      );
      return;
    }

    if (bytes.length > 3 * 1024 * 1024) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El archivo no puede superar 3MB.')),
      );
      return;
    }

    setState(() {
      _selectedAttachment = file;
      _attachmentsController.text = file.name;
    });
  }

  void _clearControllers() {
    final List<TextEditingController> controllers = [
      _positionController,
      _vacancySummaryController,
      _desiredSalaryController,
      _applicationDateController,
      _fullNameController,
      _phoneController,
      _emailController,
      _addressController,
      _birthDateController,
      _officialIdController,
      _otherDocumentsController,
      _academicLevelController,
      _institutionDetailsController,
      _previousEmploymentController,
      _responsibilitiesController,
      _salaryHistoryController,
      _languagesController,
      _officeFunctionsController,
      _softwareController,
      _softSkillsController,
      _referencesController,
      _referencesContactController,
      _openQuestionsController,
      _killerQuestionsController,
      _attachmentsController,
      _habitsGoalsController,
    ];

    for (final TextEditingController controller in controllers) {
      controller.clear();
    }
  }
}
