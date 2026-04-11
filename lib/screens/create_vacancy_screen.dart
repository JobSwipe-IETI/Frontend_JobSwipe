import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // -- Text controllers --
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();

  // -- Dropdowns --
  String? _sector;
  String? _modality;
  String? _employmentType;
  String? _experienceLevel;

  // -- Tag lists --
  List<String> _technologies = [];
  List<String> _softSkills = [];
  List<String> _benefits = [];

  // -- Dynamic lists --
  List<String> _responsibilities = [''];
  List<String> _technicalRequirements = [''];

  bool _isSubmitting = false;

  static const Map<String, String> _modalityOptions = {
    'REMOTE': 'Remoto',
    'HYBRID': 'Híbrido',
    'ON_SITE': 'Presencial',
  };

  static const Map<String, String> _employmentOptions = {
    'FULL_TIME': 'Tiempo completo',
    'PART_TIME': 'Medio tiempo',
    'FREELANCE': 'Freelance',
    'PROJECT_BASED': 'Por proyecto',
    'IMMEDIATE': 'Inmediata',
    'IN_15_DAYS': 'En 15 dias',
    'IN_30_DAYS': 'En 30 dias',
  };

  static const Map<String, String> _experienceOptions = {
    'JUNIOR': 'Junior',
    'SEMI_SENIOR': 'Semi-Senior',
    'SENIOR': 'Senior',
  };

  static const Map<String, String> _sectorOptions = {
    'Tecnologia': 'Tecnologia',
    'Finanzas': 'Finanzas',
    'Salud': 'Salud',
    'Educacion': 'Educacion',
    'Retail': 'Retail',
    'Logistica': 'Logistica',
    'Marketing': 'Marketing',
    'Construccion': 'Construccion',
    'Energia': 'Energia',
    'Servicios': 'Servicios',
    'Telecomunicaciones': 'Telecomunicaciones',
    'Otro': 'Otro',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  // ───────────────────────────── BUILD ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              icon: Icons.work_outline_rounded,
              title: 'Información General',
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Título del cargo',
                  hint: 'Ej: Desarrollador Backend Java Senior',
                  icon: Icons.badge_outlined,
                ),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Descripción del puesto',
                  hint: 'Describe el rol, objetivos y contexto del equipo...',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),
                _buildTextField(
                  controller: _locationController,
                  label: 'Ubicación',
                  hint: 'Ej: Bogotá, Colombia',
                  icon: Icons.location_on_outlined,
                ),
                _buildDropdown(
                  label: 'Sector',
                  icon: Icons.category_outlined,
                  value: _sector,
                  options: _sectorOptions,
                  onChanged: (v) => setState(() => _sector = v),
                  validator: (v) => v == null ? 'Selecciona un sector' : null,
                ),
              ],
            ),
            _buildSection(
              icon: Icons.tune_rounded,
              title: 'Condiciones del Cargo',
              children: [
                _buildDropdown(
                  label: 'Modalidad',
                  icon: Icons.laptop_mac_outlined,
                  value: _modality,
                  options: _modalityOptions,
                  onChanged: (v) => setState(() => _modality = v),
                  validator: (v) => v == null ? 'Selecciona una modalidad' : null,
                ),
                _buildDropdown(
                  label: 'Tipo de empleo',
                  icon: Icons.schedule_outlined,
                  value: _employmentType,
                  options: _employmentOptions,
                  onChanged: (v) => setState(() => _employmentType = v),
                  validator: (v) => v == null ? 'Selecciona el tipo de empleo' : null,
                ),
                _buildDropdown(
                  label: 'Nivel de experiencia',
                  icon: Icons.trending_up_rounded,
                  value: _experienceLevel,
                  options: _experienceOptions,
                  onChanged: (v) => setState(() => _experienceLevel = v),
                  validator: (v) => v == null ? 'Selecciona el nivel requerido' : null,
                ),
                _buildSalaryRow(),
              ],
            ),
            _buildSection(
              icon: Icons.person_search_outlined,
              title: 'Perfil Requerido',
              children: [
                _buildTagInput(
                  label: 'Tecnologías requeridas',
                  hint: 'Ej: Java, Spring Boot, Docker...',
                  icon: Icons.code_rounded,
                  tags: _technologies,
                  onChanged: (tags) => setState(() => _technologies = tags),
                ),
                const SizedBox(height: 8),
                _buildTagInput(
                  label: 'Habilidades blandas',
                  hint: 'Ej: Trabajo en equipo, Comunicación...',
                  icon: Icons.psychology_outlined,
                  tags: _softSkills,
                  onChanged: (tags) => setState(() => _softSkills = tags),
                ),
              ],
            ),
            _buildSection(
              icon: Icons.checklist_rounded,
              title: 'Responsabilidades y Requisitos',
              children: [
                _buildDynamicList(
                  label: 'Responsabilidades',
                  hint: 'Ej: Diseñar e implementar APIs REST...',
                  icon: Icons.task_alt_outlined,
                  items: _responsibilities,
                  onChanged: (items) => setState(() => _responsibilities = items),
                ),
                const SizedBox(height: 16),
                _buildDynamicList(
                  label: 'Requisitos técnicos',
                  hint: 'Ej: 3+ años de experiencia en Java...',
                  icon: Icons.verified_outlined,
                  items: _technicalRequirements,
                  onChanged: (items) => setState(() => _technicalRequirements = items),
                ),
              ],
            ),
            _buildSection(
              icon: Icons.card_giftcard_outlined,
              title: 'Beneficios',
              children: [
                _buildTagInput(
                  label: 'Beneficios ofrecidos',
                  hint: 'Ej: Seguro médico, Home office, Bonos...',
                  icon: Icons.stars_outlined,
                  tags: _benefits,
                  onChanged: (tags) => setState(() => _benefits = tags),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── WIDGETS ─────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Publicar Vacante',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6366F1),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Completa los campos para que los candidatos ideales encuentren tu oferta.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: JobSwipeTheme.primaryIndigo, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: JobSwipeTheme.primaryIndigo,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ?? _requiredValidator,
        decoration: _inputDecoration(label: label, hint: hint, icon: icon),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        onChanged: onChanged,
        isExpanded: true,
        decoration: _inputDecoration(label: label, hint: 'Seleccionar...', icon: icon),
        items: options.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSalaryRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money_rounded,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Rango salarial mensual (COP)',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minSalaryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _salaryValidator,
                  decoration: _inputDecoration(
                    label: 'Mínimo',
                    hint: 'Ej: 3000000',
                    icon: Icons.remove_circle_outline,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxSalaryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _maxSalaryValidator,
                  decoration: _inputDecoration(
                    label: 'Máximo',
                    hint: 'Ej: 5000000',
                    icon: Icons.add_circle_outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagInput({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> tags,
    required ValueChanged<List<String>> onChanged,
  }) {
    final TextEditingController tagController = TextEditingController();

    void addTag(String value) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty && !tags.contains(trimmed)) {
        onChanged([...tags, trimmed]);
        tagController.clear();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map(
                  (tag) => Chip(
                    label: Text(tag,
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: JobSwipeTheme.primaryIndigo,
                    deleteIconColor: Colors.white70,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      final List<String> updated = List.from(tags)..remove(tag);
                      onChanged(updated);
                    },
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tagController,
                decoration: _inputDecoration(
                  label: '',
                  hint: hint,
                  icon: Icons.add,
                ).copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: addTag,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => addTag(tagController.text),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JobSwipeTheme.primaryIndigo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDynamicList({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(items.length, (index) {
          final TextEditingController ctrl =
              TextEditingController(text: items[index]);
          ctrl.selection =
              TextSelection.collapsed(offset: ctrl.text.length);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: JobSwipeTheme.primaryIndigo),
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: ctrl,
                    decoration: _inputDecoration(
                      label: '',
                      hint: hint,
                      icon: Icons.drag_indicator,
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final List<String> updated = List.from(items);
                      updated[index] = value;
                      onChanged(updated);
                    },
                  ),
                ),
                if (items.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: Colors.red.shade400, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final List<String> updated = List.from(items)
                        ..removeAt(index);
                      onChanged(updated);
                    },
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => onChanged([...items, '']),
          icon: Icon(Icons.add_circle_outline,
              size: 16, color: JobSwipeTheme.primaryIndigo),
          label: Text(
            'Agregar ítem',
            style: TextStyle(
                fontSize: 13, color: JobSwipeTheme.primaryIndigo),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.rocket_launch_rounded),
        label: Text(
          _isSubmitting ? 'Publicando...' : 'Publicar Vacante',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: JobSwipeTheme.primaryIndigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
        borderSide:
            BorderSide(color: JobSwipeTheme.primaryIndigo, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
    );
  }

  // ───────────────────────────── VALIDATORS ─────────────────────────────

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
    return null;
  }

  String? _salaryValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa el salario mínimo';
    final double? amount = double.tryParse(value.trim());
    if (amount == null || amount < 0) return 'Ingresa un monto válido';
    return null;
  }

  String? _maxSalaryValidator(String? value) {
    final String? base = _salaryValidator(value);
    if (base != null) return base.replaceFirst('mínimo', 'máximo');
    final double min = double.tryParse(_minSalaryController.text.trim()) ?? 0;
    final double max = double.tryParse(value!.trim()) ?? 0;
    if (max < min) return 'Debe ser ≥ al salario mínimo';
    return null;
  }

  // ───────────────────────────── SUBMIT ─────────────────────────────

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final List<String> cleanResponsibilities =
        _responsibilities.where((s) => s.trim().isNotEmpty).toList();
    final List<String> cleanRequirements =
        _technicalRequirements.where((s) => s.trim().isNotEmpty).toList();

    setState(() => _isSubmitting = true);

    try {
      await _vacancyService.createVacancy(VacancyFormData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        sector: _sector!,
        modality: _modality!,
        employmentType: _employmentType!,
        experienceLevel: _experienceLevel!,
        technologies: _technologies,
        softSkills: _softSkills,
        responsibilities: cleanResponsibilities,
        technicalRequirements: cleanRequirements,
        minSalary: double.parse(_minSalaryController.text.trim()),
        maxSalary: double.parse(_maxSalaryController.text.trim()),
        benefits: _benefits,
      ));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Vacante publicada exitosamente!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _resetForm();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _minSalaryController.clear();
    _maxSalaryController.clear();
    setState(() {
      _sector = null;
      _modality = null;
      _employmentType = null;
      _experienceLevel = null;
      _technologies = [];
      _softSkills = [];
      _benefits = [];
      _responsibilities = [''];
      _technicalRequirements = [''];
    });
  }
}
