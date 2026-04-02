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
    final nextIcon = isCandidate ? Icons.business_rounded : Icons.person_rounded;
    final nextColor = isCandidate ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.isLoading ? null : _handleSwitch,
        icon: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    nextColor.withOpacity(0.6),
                  ),
                ),
              )
            : RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0)
                    .animate(_animationController),
                child: Icon(nextIcon),
              ),
        label: Text(
          'Cambiar a ${nextType}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: nextColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: nextColor.withOpacity(0.6),
          elevation: 0,
        ),
      ),
    );
  }
}
