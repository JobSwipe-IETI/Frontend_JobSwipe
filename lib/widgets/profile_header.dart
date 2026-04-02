import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../config/theme.dart';

/// Header del perfil con foto y banner editables
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isEditable,
    required this.onEditBanner,
    required this.onEditProfile,
  });

  final UserProfile profile;
  final bool isEditable;
  final VoidCallback onEditBanner;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.companyName ?? profile.name;
    final initials = displayName
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();

    return Stack(
      children: [
        // Header gradient/banner
        Container(
          width: double.infinity,
          height: 170,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF7C4DFF)],
            ),
            image: profile.bannerImageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(profile.bannerImageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.darken,
                    ),
                  )
                : null,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: isEditable
              ? Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: onEditBanner,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        Positioned(
          left: 20,
          top: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mi Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: const TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Avatar superpuesto
        Positioned(
          bottom: -20,
          left: 20,
          child: GestureDetector(
            onTap: isEditable ? onEditProfile : null,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    shape: BoxShape.circle,
                    image: profile.profileImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profile.profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A237E), Color(0xFF7C4DFF)],
                    ),
                  ),
                  child: profile.profileImageUrl.isEmpty
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                if (isEditable)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
