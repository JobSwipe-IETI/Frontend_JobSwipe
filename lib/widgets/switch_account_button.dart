import 'package:flutter/material.dart';
import '../models/user_profile.dart';

/// Botón para cambiar entre tipo de usuario (Candidato ↔ Empresa)
class SwitchAccountTypeButton extends StatefulWidget {
  const SwitchAccountTypeButton({
    super.key,
    required this.currentUserType,
    required this.isLoading,
    required this.onSwitch,
  });

  final UserType currentUserType;
  final bool isLoading;
  final VoidCallback onSwitch;

  @override
  State<SwitchAccountTypeButton> createState() =>
      _SwitchAccountTypeButtonState();
}

class _SwitchAccountTypeButtonState extends State<SwitchAccountTypeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSwitch() {
    if (!widget.isLoading) {
      _animationController.forward(from: 0.0).then((_) {
        widget.onSwitch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCandidate = widget.currentUserType == UserType.candidate;
    final nextType = isCandidate ? 'Empresa' : 'Candidato';
    final nextIcon = isCandidate
        ? Icons.business_rounded
        : Icons.person_rounded;
    final nextColor = isCandidate
        ? const Color(0xFF7C4DFF)
        : const Color(0xFF1A237E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF6)),
      ),
      child: ElevatedButton.icon(
        onPressed: widget.isLoading ? null : _handleSwitch,
        icon: widget.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : RotationTransition(
                turns: Tween(
                  begin: 0.0,
                  end: 1.0,
                ).animate(_animationController),
                child: Icon(nextIcon, size: 16),
              ),
        label: Text(
          'Cambiar a $nextType',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: nextColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: nextColor.withValues(alpha: 0.6),
          elevation: 0,
        ),
      ),
    );
  }
}
