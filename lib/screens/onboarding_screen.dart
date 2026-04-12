import 'dart:convert';

import 'package:country_picker/country_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_api_service.dart';

enum AccountType { candidate, company }

class _ExperienceDraft {
  _ExperienceDraft();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  void dispose() {
    titleController.dispose();
    companyController.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'title': titleController.text.trim(),
    'company': companyController.text.trim(),
    'startDate': startDateController.text.trim(),
    'endDate': endDateController.text.trim(),
    'current': endDateController.text.trim().isEmpty,
  };
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.jwt,
    this.userId,
    required this.onCompleted,
    required this.onLogout,
    this.initialProfile,
    this.isEditing = false,
  });

  final String jwt;
  final int? userId;
  final ValueChanged<Map<String, dynamic>> onCompleted;
  final VoidCallback onLogout;
  final UserProfile? initialProfile;
  final bool isEditing;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProfileApiService _profileApi = ProfileApiService();

  bool _isSubmitting = false;
  bool _isFormattingSalary = false;
  bool _isExtractingCv = false;
  bool _showCandidateManualForm = false;
  bool _candidatePhoneValid = true;
  bool _companyPhoneValid = true;
  String _candidatePhoneIsoCode = 'CO';
  String _companyPhoneIsoCode = 'CO';

  String? _error;
  AccountType? _accountType;
  String? _candidateNationality;
  String? _companyNationality;
  String? _selectedAvailability;
  String? _selectedIndustry;
  String? _selectedCompanySize;
  String? _selectedCvFileName;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _professionalTitleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _expectedSalaryController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _linkInputController = TextEditingController();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyDescriptionController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _companySizeController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _headquartersController = TextEditingController();
  final TextEditingController _companyNationalityController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _legalIdController = TextEditingController();
  final TextEditingController _hiringContactNameController = TextEditingController();
  final TextEditingController _hiringContactEmailController = TextEditingController();

  final TextEditingController _skillInputController = TextEditingController();
  final List<String> _candidateSkills = <String>[];
  final List<String> _professionalLinks = <String>[];
  final List<String> _selectedLanguages = <String>[];
  final List<_ExperienceDraft> _candidateExperiences = <_ExperienceDraft>[];
  String? _languageToAdd;

  static const List<String> _educationOptions = <String>[
    'Bachillerato',
    'Tecnico',
    'Tecnologo',
    'Pregrado',
    'Especializacion',
    'Maestria',
    'Doctorado',
    'Bootcamp',
    'Otro',
  ];

  static const List<String> _availabilityOptions = <String>[
    'Tiempo completo',
    'Medio tiempo',
    'Freelance',
    'Por proyecto',
    'Inmediata',
    'En 15 dias',
    'En 30 dias',
  ];

  static const List<String> _industryOptions = <String>[
    'Tecnologia',
    'Finanzas',
    'Salud',
    'Educacion',
    'Retail',
    'Logistica',
    'Marketing',
    'Construccion',
    'Energia',
    'Servicios',
    'Telecomunicaciones',
    'Otro',
  ];

  static const List<String> _companySizeOptions = <String>[
    '1-10 empleados',
    '11-50 empleados',
    '51-200 empleados',
    '201-500 empleados',
    '501-1000 empleados',
    '1000+ empleados',
  ];

  static const List<String> _languageOptions = <String>[
    'Espanol',
    'English',
    'Portugues',
    'Frances',
    'Aleman',
    'Italiano',
    'Neerlandes',
    'Ruso',
    'Chino',
    'Japones',
    'Coreano',
    'Arabe',
    'Hindi',
    'Turco',
    'Polaco',
    'Sueco',
    'Noruego',
    'Danes',
    'Finlandes',
    'Checo',
  ];

  @override
  void initState() {
    super.initState();
    _showCandidateManualForm = widget.isEditing;
    _hydrateFromInitialProfile();
  }

  void _hydrateFromInitialProfile() {
    final UserProfile? profile = widget.initialProfile;
    if (profile == null) {
      return;
    }

    _accountType = profile.userType == UserType.company
        ? AccountType.company
        : AccountType.candidate;

    _displayNameController.text = profile.name;
    _professionalTitleController.text = profile.professionalTitle ?? '';
    _summaryController.text = profile.description;
    _educationController.text = profile.education ?? '';
    _locationController.text = profile.location ?? '';
    _nationalityController.text = profile.nationality ?? '';
    _candidateNationality = profile.nationality;
    _selectedAvailability = _availabilityOptions.contains(profile.availability)
        ? profile.availability
        : null;
    _phoneController.text = profile.phoneNumber ?? '';
    _expectedSalaryController.text = profile.expectedSalary?.toString() ?? '';
    _availabilityController.text = profile.availability ?? '';

    _professionalLinks
      ..clear()
      ..addAll(
        [
          profile.githubUrl,
          profile.linkedinUrl,
          profile.portfolioUrl,
        ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty),
      );

    _companyNameController.text = profile.companyName ?? profile.name;
    _companyDescriptionController.text = profile.companyDescription ?? profile.description;
    _industryController.text = profile.industry ?? '';
    _selectedIndustry = _industryOptions.contains(profile.industry)
        ? profile.industry
        : null;
    _companySizeController.text = profile.companySize ?? '';
    _selectedCompanySize = _companySizeOptions.contains(profile.companySize)
        ? profile.companySize
        : null;
    _websiteController.text = profile.website ?? '';
    _headquartersController.text = profile.headquartersLocation ?? '';
    _companyNationalityController.text = profile.nationality ?? '';
    _companyNationality = profile.nationality;
    _companyPhoneController.text = profile.phoneNumber ?? '';
    _legalIdController.text = profile.legalId ?? '';
    _hiringContactNameController.text = profile.hiringContactName ?? '';
    _hiringContactEmailController.text = profile.hiringContactEmail ?? '';

    _candidateSkills
      ..clear()
      ..addAll(_parseList(profile.skills));

    _selectedLanguages
      ..clear()
      ..addAll(_parseList(profile.languages).toSet().toList());

    _candidateExperiences
      ..clear()
      ..addAll(_parseExperiences(profile.experience));

    if (_candidateExperiences.isEmpty && _accountType == AccountType.candidate) {
      _candidateExperiences.add(_ExperienceDraft());
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _professionalTitleController.dispose();
    _summaryController.dispose();
    _educationController.dispose();
    _locationController.dispose();
    _nationalityController.dispose();
    _phoneController.dispose();
    _expectedSalaryController.dispose();
    _availabilityController.dispose();
    _linkInputController.dispose();
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _industryController.dispose();
    _companySizeController.dispose();
    _websiteController.dispose();
    _headquartersController.dispose();
    _companyNationalityController.dispose();
    _companyPhoneController.dispose();
    _legalIdController.dispose();
    _hiringContactNameController.dispose();
    _hiringContactEmailController.dispose();
    _skillInputController.dispose();

    for (final _ExperienceDraft draft in _candidateExperiences) {
      draft.dispose();
    }

    super.dispose();
  }

  List<String> _parseList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <String>[];
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map<String>((dynamic item) => item.toString().trim())
            .where((String e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return raw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  List<_ExperienceDraft> _parseExperiences(String? raw) {
    final List<_ExperienceDraft> result = <_ExperienceDraft>[];
    if (raw == null || raw.trim().isEmpty) {
      return result;
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final Object item in decoded) {
          if (item is Map<String, dynamic>) {
            final _ExperienceDraft draft = _ExperienceDraft();
            draft.titleController.text = item['title']?.toString() ?? '';
            draft.companyController.text = item['company']?.toString() ?? '';
            draft.startDateController.text = item['startDate']?.toString() ?? '';
            draft.endDateController.text = item['endDate']?.toString() ?? '';
            result.add(draft);
          }
        }
      }
    } catch (_) {}

    return result;
  }

  Future<void> _submit() async {
    if (_accountType == null || !_formKey.currentState!.validate()) {
      return;
    }

    final int? userId = widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    if (userId == null) {
      setState(() {
        _error = 'No se pudo identificar el usuario autenticado.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (_accountType == AccountType.candidate) {
        final Map<String, dynamic> payload = <String, dynamic>{
          'displayName': _displayNameController.text.trim(),
          'professionalTitle': _professionalTitleController.text.trim(),
          'summary': _summaryController.text.trim(),
          'skills': _candidateSkills,
          'experiences': _candidateExperiences.map((d) => d.toMap()).toList(),
          'education': _educationController.text.trim(),
          'location': _locationController.text.trim(),
          'nationality': _candidateNationality ?? _nationalityController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'languages': _selectedLanguages.join(', '),
          'sector': _selectedIndustry ?? _industryController.text.trim(),
          'expectedSalary': _parseExpectedSalary(),
          'availability': _selectedAvailability ?? _availabilityController.text.trim(),
          'portfolioUrl': _firstPortfolioLink(),
          'githubUrl': _firstLinkContaining('github.com'),
          'linkedinUrl': _firstLinkContaining('linkedin.com'),
        };

        await _profileApi.createCandidateProfile(
          jwt: widget.jwt,
          userId: userId,
          payload: payload,
        );

        final String? newJwt = await _profileApi.updateUserRole(
          jwt: widget.jwt,
          role: 'CANDIDATE',
        );

        widget.onCompleted(<String, dynamic>{
          'role': 'CANDIDATE',
          if (newJwt != null) 'newJwt': newJwt,
          ...payload,
        });
      } else {
        final Map<String, dynamic> payload = <String, dynamic>{
          'companyName': _companyNameController.text.trim(),
          'companyDescription': _companyDescriptionController.text.trim(),
          'legalId': _legalIdController.text.trim(),
          'industry': _selectedIndustry ?? _industryController.text.trim(),
          'companySize': _selectedCompanySize ?? _companySizeController.text.trim(),
          'website': _websiteController.text.trim(),
          'headquartersLocation': _headquartersController.text.trim(),
          'nationality': _companyNationality ?? _companyNationalityController.text.trim(),
          'phoneNumber': _companyPhoneController.text.trim(),
          'hiringContactName': _hiringContactNameController.text.trim(),
          'hiringContactEmail': _hiringContactEmailController.text.trim(),
        };

        await _profileApi.createCompanyProfile(
          jwt: widget.jwt,
          userId: userId,
          payload: payload,
        );

        final String? newJwt = await _profileApi.updateUserRole(
          jwt: widget.jwt,
          role: 'COMPANY',
        );

        widget.onCompleted(<String, dynamic>{
          'role': 'COMPANY',
          if (newJwt != null) 'newJwt': newJwt,
          ...payload,
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu registro'),
        actions: <Widget>[
          TextButton(
            onPressed: _isSubmitting ? null : widget.onLogout,
            child: const Text('Salir'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!widget.isEditing) ...<Widget>[
                  const Text(
                    'Que tipo de cuenta quieres usar?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _typeCard(
                          type: AccountType.candidate,
                          title: 'Candidato',
                          subtitle: 'Busco trabajo',
                          icon: Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _typeCard(
                          type: AccountType.company,
                          title: 'Empresa',
                          subtitle: 'Publico vacantes',
                          icon: Icons.business_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (_accountType == AccountType.candidate) ..._candidateFields(),
                if (_accountType == AccountType.company) ..._companyFields(),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_accountType == null ||
                            _isSubmitting ||
                            (_accountType == AccountType.candidate && !_isCandidateFormVisible))
                        ? null
                        : _submit,
                    child: Text(
                      _isSubmitting
                          ? 'Guardando...'
                          : widget.isEditing
                              ? 'Guardar cambios'
                              : 'Continuar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard({
    required AccountType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _accountType == type;

    return InkWell(
      onTap: () => setState(() {
        _accountType = type;
        if (type == AccountType.candidate && _candidateExperiences.isEmpty) {
          _candidateExperiences.add(_ExperienceDraft());
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  List<Widget> _candidateFields() {
    final List<Widget> widgets = <Widget>[
      _buildCandidateStartCard(),
    ];

    if (!_isCandidateFormVisible) {
      return widgets;
    }

    widgets.addAll(<Widget>[
      _field(
        controller: _displayNameController,
        label: 'Nombre completo *',
        validator: (v) => _requiredWithLength(v, field: 'Nombre completo', min: 2, max: 80),
      ),
      _field(
        controller: _professionalTitleController,
        label: 'Titulo profesional *',
        validator: (v) => _requiredWithLength(v, field: 'Titulo profesional', min: 3, max: 120),
      ),
      _field(
        controller: _summaryController,
        label: 'Resumen *',
        maxLines: 3,
        validator: (v) => _requiredWithLength(v, field: 'Resumen', min: 30, max: 1500),
      ),
      _buildLinksEditor(),
      _buildSkillsEditor(),
      _buildExperiencesEditor(),
      _field(
        controller: _educationController,
        label: 'Educacion',
        validator: (v) => _optionalMax(v, field: 'Educacion', max: 300),
      ),
      _field(
        controller: _locationController,
        label: 'Ubicacion',
        validator: (v) => _optionalMax(v, field: 'Ubicacion', max: 120),
      ),
      _dropdownField(
        label: 'Sector *',
        value: _selectedIndustry,
        items: _industryOptions,
        onChanged: (value) => setState(() {
          _selectedIndustry = value;
          _industryController.text = value ?? '';
        }),
        validator: (value) => value == null || value.isEmpty ? 'Selecciona un sector' : null,
      ),
      _countryPickerField(
        label: 'Nacionalidad *',
        controller: _nationalityController,
        value: _candidateNationality,
        onSelected: (country) {
          setState(() {
            _candidateNationality = country.name;
            _candidatePhoneIsoCode = country.countryCode;
            _nationalityController.text = country.name;
          });
        },
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Nacionalidad es obligatoria' : null,
      ),
      _internationalPhoneField(
        controller: _phoneController,
        label: 'Telefono',
        isoCode: _candidatePhoneIsoCode,
        onIsoChanged: (iso) => _candidatePhoneIsoCode = iso,
        onValidityChanged: (isValid) => _candidatePhoneValid = isValid,
        validator: (_) {
          final String text = _phoneController.text.trim();
          if (text.isEmpty) {
            return null;
          }
          return _candidatePhoneValid ? null : 'Telefono invalido para el pais seleccionado';
        },
      ),
      _buildLanguagesCatalogEditor(),
      _field(
        controller: _expectedSalaryController,
        label: 'Salario esperado (USD)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _salaryValidator,
        suffixText: 'USD',
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        onChanged: _onSalaryChanged,
      ),
      _dropdownField(
        label: 'Disponibilidad *',
        value: _selectedAvailability,
        items: _availabilityOptions,
        onChanged: (value) => setState(() => _selectedAvailability = value),
        validator: (value) => value == null || value.isEmpty ? 'Selecciona disponibilidad' : null,
      ),
    ]);

    return widgets;
  }

  bool get _isCandidateFormVisible {
    return _showCandidateManualForm || _hasCandidatePrefillData;
  }

  bool get _hasCandidatePrefillData {
    return _displayNameController.text.trim().isNotEmpty ||
        _professionalTitleController.text.trim().isNotEmpty ||
        _summaryController.text.trim().isNotEmpty ||
        _industryController.text.trim().isNotEmpty ||
        _candidateSkills.isNotEmpty ||
        _selectedLanguages.isNotEmpty ||
        _candidateExperiences.any(
          (e) =>
              e.titleController.text.trim().isNotEmpty ||
              e.companyController.text.trim().isNotEmpty ||
              e.startDateController.text.trim().isNotEmpty ||
              e.endDateController.text.trim().isNotEmpty,
        );
  }

  Widget _buildCandidateStartCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Comienza con tu hoja de vida',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Sube tu CV para autocompletar los campos o llenalos manualmente.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isExtractingCv ? null : _pickAndExtractCv,
              icon: _isExtractingCv
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(_isExtractingCv ? 'Extrayendo CV...' : 'Subir hoja de vida (PDF)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showCandidateManualForm = true;
                });
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Llenar manualmente'),
            ),
            if (_selectedCvFileName != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Archivo seleccionado: $_selectedCvFileName',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinksEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Links profesionales', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _linkInputController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Agregar link (GitHub, LinkedIn, portafolio)',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addLink(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addLink, child: const Text('Agregar')),
          ],
        ),
        const SizedBox(height: 8),
        if (_professionalLinks.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Agrega uno o varios links profesionales',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _professionalLinks
                  .map(
                    (link) => Chip(
                      label: Text(link),
                      onDeleted: () => setState(() => _professionalLinks.remove(link)),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _pickAndExtractCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final PlatformFile file = result.files.single;
    final List<int>? bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _error = 'No se pudo leer el PDF seleccionado.';
      });
      return;
    }

    setState(() {
      _isExtractingCv = true;
      _error = null;
      _selectedCvFileName = file.name;
    });

    try {
      final Map<String, dynamic> extracted = await _profileApi.extractCandidateProfileFromCv(
        fileName: file.name,
        fileBytes: bytes,
      );
      _applyExtractedCandidateProfile(extracted);
      setState(() {
        _showCandidateManualForm = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingCv = false;
        });
      }
    }
  }

  void _applyExtractedCandidateProfile(Map<String, dynamic> profile) {
    final Map<String, dynamic> p =
        profile['candidateProfile'] is Map<String, dynamic>
        ? profile['candidateProfile'] as Map<String, dynamic>
        : profile;

    setState(() {
      _displayNameController.text =
          p['displayName']?.toString() ??
          p['fullName']?.toString() ??
          p['name']?.toString() ??
          _displayNameController.text;
      _professionalTitleController.text = p['professionalTitle']?.toString() ?? _professionalTitleController.text;
      _summaryController.text = p['summary']?.toString() ?? _summaryController.text;
      _locationController.text = p['location']?.toString() ?? _locationController.text;

      final String? extractedSector = _normalizeExtractedSector(
        p['sector']?.toString() ?? p['industry']?.toString(),
      );
      if (extractedSector != null) {
        _selectedIndustry = extractedSector;
        _industryController.text = extractedSector;
      }

      final String? extractedNationality = _normalizeExtractedNationality(
        p['nationality']?.toString() ??
            p['country']?.toString() ??
            p['pais']?.toString(),
      );
      if (extractedNationality != null) {
        _candidateNationality = extractedNationality;
        _nationalityController.text = extractedNationality;
      }

      _phoneController.text = p['phoneNumber']?.toString() ?? _phoneController.text;
      _expectedSalaryController.text = p['expectedSalary']?.toString() ?? _expectedSalaryController.text;
      _availabilityController.text = p['availability']?.toString() ?? _availabilityController.text;
      _educationController.text = _formatEducationValue(p['education']);

      _professionalLinks
        ..clear()
        ..addAll(_extractProfessionalLinks(p));

      _candidateSkills
        ..clear()
        ..addAll(_extractStringList(p['skills']));

      _selectedLanguages
        ..clear()
        ..addAll(_extractLanguages(p['languages']));

      _candidateExperiences
        ..clear()
        ..addAll(_extractExperiences(p['experience']));

      if (_candidateExperiences.isEmpty) {
        _candidateExperiences.add(_ExperienceDraft());
      }

      final String? extractedAvailability = p['availability']?.toString();
      if (extractedAvailability != null && extractedAvailability.trim().isNotEmpty) {
        _selectedAvailability = _availabilityOptions.contains(extractedAvailability)
            ? extractedAvailability
            : null;
      }
    });
  }

  String? _normalizeExtractedSector(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return null;
    }

    final lower = value.toLowerCase();
    final Map<String, String> aliases = {
      'tecnologia': 'Tecnologia',
      'technology': 'Tecnologia',
      'tech': 'Tecnologia',
      'software': 'Tecnologia',
      'finanzas': 'Finanzas',
      'finance': 'Finanzas',
      'salud': 'Salud',
      'health': 'Salud',
      'educacion': 'Educacion',
      'education': 'Educacion',
      'retail': 'Retail',
      'logistica': 'Logistica',
      'logistics': 'Logistica',
      'marketing': 'Marketing',
      'construccion': 'Construccion',
      'construction': 'Construccion',
      'energia': 'Energia',
      'energy': 'Energia',
      'servicios': 'Servicios',
      'services': 'Servicios',
      'telecomunicaciones': 'Telecomunicaciones',
      'telecommunications': 'Telecomunicaciones',
      'otro': 'Otro',
      'other': 'Otro',
    };

    if (aliases.containsKey(lower)) {
      return aliases[lower];
    }

    for (final option in _industryOptions) {
      if (option.toLowerCase() == lower) {
        return option;
      }
    }

    return 'Otro';
  }

  String? _normalizeExtractedNationality(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return null;
    }

    final lower = value.toLowerCase();
    if (lower == 'colombian') {
      return 'Colombia';
    }
    if (lower == 'mexican') {
      return 'Mexico';
    }
    if (lower == 'argentinian') {
      return 'Argentina';
    }
    if (lower == 'peruvian') {
      return 'Peru';
    }
    if (lower == 'chilean') {
      return 'Chile';
    }

    return value;
  }

  List<String> _extractProfessionalLinks(Map<String, dynamic> profile) {
    final Set<String> links = <String>{};

    for (final value in <dynamic>[
      profile['links'],
      profile['github'],
      profile['githubUrl'],
      profile['linkedin'],
      profile['linkedinUrl'],
      profile['portfolioUrl'],
      profile['website'],
    ]) {
      links.addAll(_extractStringList(value));
    }

    return links.where((link) => _urlValidator(link, field: 'Link') == null).toList();
  }

  List<String> _extractLanguages(dynamic value) {
    final mapped = _extractStringList(value)
        .map(_normalizeLanguage)
        .where((lang) => lang.isNotEmpty)
        .toSet()
        .toList();

    return mapped.where((lang) => _languageOptions.contains(lang)).toList();
  }

  String _normalizeLanguage(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return '';
    }

    if (value == 'es' || value == 'esp' || value == 'espanol' || value == 'español' || value == 'spanish') {
      return 'Espanol';
    }

    if (value == 'en' || value == 'eng' || value == 'ingles' || value == 'inglés' || value == 'english') {
      return 'English';
    }

    if (value == 'pt' || value == 'por' || value == 'portugues' || value == 'portuguese') {
      return 'Portugues';
    }

    if (value == 'fr' || value == 'french' || value == 'frances' || value == 'francés') {
      return 'Frances';
    }

    if (value == 'de' || value == 'german' || value == 'aleman' || value == 'alemán') {
      return 'Aleman';
    }

    final title = value[0].toUpperCase() + value.substring(1);
    return _languageOptions.firstWhere(
      (lang) => lang.toLowerCase() == title.toLowerCase(),
      orElse: () => '',
    );
  }

  List<String> _extractStringList(dynamic value) {
    if (value == null) {
      return <String>[];
    }

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final String text = value.toString().trim();
    return text.isEmpty ? <String>[] : <String>[text];
  }

  List<_ExperienceDraft> _extractExperiences(dynamic value) {
    final List<_ExperienceDraft> result = <_ExperienceDraft>[];
    if (value is! List) {
      return result;
    }

    for (final dynamic item in value) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final _ExperienceDraft draft = _ExperienceDraft();
      draft.titleController.text = item['role']?.toString() ?? item['title']?.toString() ?? '';
      draft.companyController.text = item['company']?.toString() ?? item['project']?.toString() ?? '';
      draft.startDateController.text = _normalizeExperienceDate(
        item['start']?.toString() ?? item['startDate']?.toString(),
      );
      draft.endDateController.text = _normalizeExperienceDate(
        item['end']?.toString() ?? item['endDate']?.toString(),
        allowEmptyForCurrent: true,
      );
      result.add(draft);
    }

    return result;
  }

  String _normalizeExperienceDate(String? raw, {bool allowEmptyForCurrent = false}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '';
    }

    final lower = value.toLowerCase();
    if (allowEmptyForCurrent && (lower == 'actual' || lower == 'present' || lower == 'current' || lower == 'hoy')) {
      return '';
    }

    final iso = DateTime.tryParse(value);
    if (iso != null) {
      return _formatDate(iso);
    }

    final yearOnly = RegExp(r'^(\d{4})$').firstMatch(value);
    if (yearOnly != null) {
      return '${yearOnly.group(1)}-01-01';
    }

    final yearMonth = RegExp(r'^(\d{4})[-/](\d{1,2})$').firstMatch(value);
    if (yearMonth != null) {
      final year = yearMonth.group(1)!;
      final month = int.parse(yearMonth.group(2)!).toString().padLeft(2, '0');
      return '$year-$month-01';
    }

    final monthYear = RegExp(r'^(\d{1,2})[-/](\d{4})$').firstMatch(value);
    if (monthYear != null) {
      final month = int.parse(monthYear.group(1)!).toString().padLeft(2, '0');
      final year = monthYear.group(2)!;
      return '$year-$month-01';
    }

    final ddmmyyyy = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(value);
    if (ddmmyyyy != null) {
      final day = int.parse(ddmmyyyy.group(1)!).toString().padLeft(2, '0');
      final month = int.parse(ddmmyyyy.group(2)!).toString().padLeft(2, '0');
      final year = ddmmyyyy.group(3)!;
      return '$year-$month-$day';
    }

    return value;
  }

  String _formatEducationValue(dynamic education) {
    if (education == null) {
      return '';
    }

    if (education is String) {
      return education.trim();
    }

    if (education is List && education.isNotEmpty) {
      final dynamic first = education.first;
      if (first is Map<String, dynamic>) {
        final List<String?> rawParts = <String?>[
          first['degree']?.toString(),
          first['institution']?.toString(),
          first['status']?.toString(),
        ];
        final parts = rawParts
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        return parts.join(' - ');
      }
      return first.toString().trim();
    }

    return education.toString().trim();
  }

  List<Widget> _companyFields() {
    return <Widget>[
      _field(
        controller: _companyNameController,
        label: 'Nombre empresa *',
        validator: (v) => _requiredWithLength(v, field: 'Nombre empresa', min: 2, max: 120),
      ),
      _field(
        controller: _companyDescriptionController,
        label: 'Descripcion *',
        maxLines: 3,
        validator: (v) => _requiredWithLength(v, field: 'Descripcion', min: 30, max: 2000),
      ),
      _dropdownField(
        label: 'Industria',
        value: _selectedIndustry,
        items: _industryOptions,
        onChanged: (value) => setState(() {
          _selectedIndustry = value;
          _industryController.text = value ?? '';
        }),
        validator: (value) => value == null || value.isEmpty ? 'Selecciona la industria' : null,
      ),
      _dropdownField(
        label: 'Tamano empresa',
        value: _selectedCompanySize,
        items: _companySizeOptions,
        onChanged: (value) => setState(() {
          _selectedCompanySize = value;
          _companySizeController.text = value ?? '';
        }),
        validator: (value) => value == null || value.isEmpty ? 'Selecciona el tamano de la empresa' : null,
      ),
      _field(
        controller: _websiteController,
        label: 'Sitio web',
        keyboardType: TextInputType.url,
        validator: (v) => _urlValidator(v, field: 'Sitio web'),
      ),
      _field(
        controller: _headquartersController,
        label: 'Ubicacion sede',
        validator: (v) => _optionalMax(v, field: 'Ubicacion sede', max: 150),
      ),
      _countryPickerField(
        label: 'Pais/Nacionalidad *',
        controller: _companyNationalityController,
        value: _companyNationality,
        onSelected: (country) {
          setState(() {
            _companyNationality = country.name;
            _companyPhoneIsoCode = country.countryCode;
            _companyNationalityController.text = country.name;
          });
        },
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Pais/Nacionalidad es obligatorio' : null,
      ),
      _internationalPhoneField(
        controller: _companyPhoneController,
        label: 'Telefono',
        isoCode: _companyPhoneIsoCode,
        onIsoChanged: (iso) => _companyPhoneIsoCode = iso,
        onValidityChanged: (isValid) => _companyPhoneValid = isValid,
        validator: (_) {
          final String text = _companyPhoneController.text.trim();
          if (text.isEmpty) {
            return null;
          }
          return _companyPhoneValid ? null : 'Telefono invalido para el pais seleccionado';
        },
      ),
      _field(
        controller: _legalIdController,
        label: 'NIT / ID legal',
        validator: (v) => _optionalMax(v, field: 'NIT / ID legal', max: 80),
      ),
      _field(
        controller: _hiringContactNameController,
        label: 'Nombre contacto contratacion',
        validator: (v) => _optionalMax(v, field: 'Nombre contacto contratacion', max: 120),
      ),
      _field(
        controller: _hiringContactEmailController,
        label: 'Email contacto contratacion',
        keyboardType: TextInputType.emailAddress,
        validator: _emailValidator,
      ),
    ];
  }

  Widget _buildSkillsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Habilidades', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _skillInputController,
                decoration: const InputDecoration(
                  labelText: 'Agregar habilidad',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addSkill, child: const Text('Agregar')),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _candidateSkills
                .map((skill) => Chip(
                      label: Text(skill),
                      onDeleted: () => setState(() => _candidateSkills.remove(skill)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLanguagesCatalogEditor() {
    final List<String> availableLanguages = _languageOptions
        .where((language) => !_selectedLanguages.contains(language))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Idiomas', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('lang-${_selectedLanguages.join('|')}'),
          initialValue: availableLanguages.contains(_languageToAdd) ? _languageToAdd : null,
          items: availableLanguages
              .map(
                (language) => DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _languageToAdd = value;
              if (!_selectedLanguages.contains(value)) {
                _selectedLanguages.add(value);
              }
              _languageToAdd = null;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Agregar idioma del catalogo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedLanguages.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Selecciona uno o mas idiomas',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedLanguages
                  .map(
                    (language) => Chip(
                      label: Text(language),
                      onDeleted: () => setState(() => _selectedLanguages.remove(language)),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildExperiencesEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('Experiencia', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addExperienceDraft,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar experiencia'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ..._candidateExperiences.asMap().entries.map((entry) {
          final int index = entry.key;
          final _ExperienceDraft draft = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: <Widget>[
                  _field(controller: draft.titleController, label: 'Cargo *'),
                  _field(controller: draft.companyController, label: 'Empresa *'),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _dateField(
                          controller: draft.startDateController,
                          label: 'Fecha inicio *',
                          onTap: () => _pickExperienceDate(draft, isStart: true),
                          validator: (v) => _validateExperienceDate(draft, v, isStart: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dateField(
                          controller: draft.endDateController,
                          label: 'Fecha fin / Actual',
                          onTap: () => _pickExperienceDate(draft, isStart: false),
                          validator: (v) => _validateExperienceDate(draft, v, isStart: false),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _removeExperienceDraft(index),
                      child: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_candidateExperiences.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Agrega al menos una experiencia laboral.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _pickExperienceDate(_ExperienceDraft draft, {required bool isStart}) async {
    final DateTime now = DateTime.now();
    final String raw = isStart
        ? draft.startDateController.text.trim()
        : draft.endDateController.text.trim();
    final DateTime initialDate = DateTime.tryParse(raw) ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        draft.startDateController.text = _formatDate(picked);
        final DateTime? endDate = DateTime.tryParse(draft.endDateController.text.trim());
        if (endDate != null && endDate.isBefore(picked)) {
          draft.endDateController.clear();
        }
      } else {
        draft.endDateController.text = _formatDate(picked);
      }
    });
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _validateExperienceDate(
    _ExperienceDraft draft,
    String? value, {
    required bool isStart,
  }) {
    final String text = value?.trim() ?? '';

    if (isStart) {
      if (text.isEmpty) {
        return 'La fecha de inicio es obligatoria';
      }
      return DateTime.tryParse(text) == null ? 'Selecciona una fecha valida' : null;
    }

    if (text.isEmpty) {
      return null;
    }

    final DateTime? start = DateTime.tryParse(draft.startDateController.text.trim());
    final DateTime? end = DateTime.tryParse(text);
    if (end == null) {
      return 'Selecciona una fecha valida';
    }
    if (start != null && end.isBefore(start)) {
      return 'La fecha fin no puede ser anterior al inicio';
    }
    return null;
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? suffixText,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    final bool isRequired = label.contains('*');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffixText,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
        onTap: onTap,
        onChanged: onChanged,
        validator: validator ??
            (isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  }
                : null),
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return _field(
      controller: controller,
      label: label,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      suffixIcon: const Icon(Icons.calendar_month_rounded),
    );
  }

  Widget _internationalPhoneField({
    required TextEditingController controller,
    required String label,
    required String isoCode,
    required ValueChanged<String> onIsoChanged,
    required ValueChanged<bool> onValidityChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InternationalPhoneNumberInput(
        textFieldController: controller,
        initialValue: PhoneNumber(isoCode: isoCode),
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.DROPDOWN,
          useBottomSheetSafeArea: true,
        ),
        autoValidateMode: AutovalidateMode.onUserInteraction,
        inputDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        formatInput: false,
        keyboardType: const TextInputType.numberWithOptions(signed: false),
        onInputChanged: (PhoneNumber number) {
          final String? iso = number.isoCode;
          if (iso != null && iso.isNotEmpty) {
            onIsoChanged(iso);
          }
        },
        onInputValidated: onValidityChanged,
        validator: validator,
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: (value == null || value.isEmpty) ? null : value,
        items: items
            .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
            .toList(),
        onChanged: items.isEmpty ? null : onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _countryPickerField({
    required String label,
    required TextEditingController controller,
    required String? value,
    required ValueChanged<Country> onSelected,
    String? Function(String?)? validator,
  }) {
    controller.text = value ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: true,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        validator: validator,
        onTap: () {
          showCountryPicker(
            context: context,
            showPhoneCode: true,
            onSelect: onSelected,
          );
        },
      ),
    );
  }

  String? _requiredWithLength(
    String? value, {
    required String field,
    required int min,
    required int max,
  }) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '$field es obligatorio';
    }
    if (text.length < min) {
      return '$field debe tener al menos $min caracteres';
    }
    if (text.length > max) {
      return '$field no puede superar $max caracteres';
    }
    return null;
  }

  String? _optionalMax(String? value, {required String field, required int max}) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (text.length > max) {
      return '$field no puede superar $max caracteres';
    }
    return null;
  }

  String? _salaryValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final double? salary = _parseExpectedSalary();
    if (salary == null) {
      return 'Salario esperado invalido. Usa solo numeros';
    }
    if (salary < 0) {
      return 'El salario esperado no puede ser negativo';
    }
    return null;
  }

  String? _urlValidator(String? value, {required String field}) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(text);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return '$field debe iniciar con http:// o https://';
    }
    return null;
  }

  void _addLink() {
    final value = _linkInputController.text.trim();
    final validation = _urlValidator(value, field: 'Link');
    if (validation != null) {
      setState(() {
        _error = validation;
      });
      return;
    }

    if (value.isEmpty || _professionalLinks.contains(value)) {
      _linkInputController.clear();
      return;
    }

    setState(() {
      _error = null;
      _professionalLinks.add(value);
      _linkInputController.clear();
    });
  }

  String _firstLinkContaining(String domain) {
    for (final link in _professionalLinks) {
      if (link.toLowerCase().contains(domain)) {
        return link;
      }
    }
    return '';
  }

  String _firstPortfolioLink() {
    for (final link in _professionalLinks) {
      final lower = link.toLowerCase();
      if (!lower.contains('github.com') && !lower.contains('linkedin.com')) {
        return link;
      }
    }
    return '';
  }

  String? _emailValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Email de contacto invalido';
    }
    if (text.length > 160) {
      return 'Email de contacto no puede superar 160 caracteres';
    }
    return null;
  }

  void _onSalaryChanged(String value) {
    if (_isFormattingSalary) {
      return;
    }

    final String formatted = _formatSalaryInput(value);
    if (formatted == value) {
      return;
    }

    _isFormattingSalary = true;
    _expectedSalaryController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingSalary = false;
  }

  String _formatSalaryInput(String input) {
    final String sanitized = input.replaceAll(RegExp(r'[^0-9\.,]'), '');
    if (sanitized.isEmpty) {
      return '';
    }

    final int lastDot = sanitized.lastIndexOf('.');
    final int lastComma = sanitized.lastIndexOf(',');
    final int decimalSeparatorIndex = lastDot > lastComma ? lastDot : lastComma;

    String integerPart = sanitized;
    String decimalPart = '';

    if (decimalSeparatorIndex != -1) {
      integerPart = sanitized.substring(0, decimalSeparatorIndex);
      decimalPart = sanitized.substring(decimalSeparatorIndex + 1);
    }

    integerPart = integerPart.replaceAll(RegExp(r'[^0-9]'), '');
    decimalPart = decimalPart.replaceAll(RegExp(r'[^0-9]'), '');

    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    final String formattedInteger = _withThousandSeparators(integerPart);
    if (decimalSeparatorIndex == -1) {
      return formattedInteger;
    }

    if (decimalPart.isEmpty) {
      return '$formattedInteger.';
    }

    return '$formattedInteger.$decimalPart';
  }

  String _withThousandSeparators(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    int groupCount = 0;

    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      groupCount++;
      if (groupCount == 3 && i > 0) {
        buffer.write(',');
        groupCount = 0;
      }
    }

    return buffer.toString().split('').reversed.join();
  }

  double? _parseExpectedSalary() {
    final String raw = _expectedSalaryController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    final String normalized = raw.replaceAll(',', '');
    return double.tryParse(normalized);
  }

  void _addSkill() {
    final String skill = _skillInputController.text.trim();
    if (skill.isEmpty) {
      return;
    }

    setState(() {
      if (!_candidateSkills.contains(skill)) {
        _candidateSkills.add(skill);
      }
      _skillInputController.clear();
    });
  }

  void _addExperienceDraft() {
    setState(() {
      _candidateExperiences.add(_ExperienceDraft());
    });
  }

  void _removeExperienceDraft(int index) {
    setState(() {
      final _ExperienceDraft draft = _candidateExperiences.removeAt(index);
      draft.dispose();
    });
  }
}
