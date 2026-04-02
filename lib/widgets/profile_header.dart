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
    return Stack(
      children: [
        // Banner
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: JobSwipeTheme.primaryIndigo.withOpacity(0.1),
            image: profile.bannerImageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(profile.bannerImageUrl),
                    fit: BoxFit.cover,
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
                        color: Colors.black.withOpacity(0.3),
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
        // Foto de perfil (superpuesta)
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
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    shape: BoxShape.circle,
                    image: profile.profileImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profile.profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: JobSwipeTheme.primaryIndigo.withOpacity(0.2),
                  ),
                  child: profile.profileImageUrl.isEmpty
                      ? Icon(
                          profile.userType == UserType.candidate
                              ? Icons.person_rounded
                              : Icons.business_rounded,
                          size: 50,
                          color: JobSwipeTheme.primaryIndigo,
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
                        color: JobSwipeTheme.primaryIndigo,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
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
