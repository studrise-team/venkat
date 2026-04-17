import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/user_model.dart';

class StudentSidebar extends StatelessWidget {
  final UserModel? user;
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onLogout;
  final bool isPermanent;

  const StudentSidebar({
    super.key,
    required this.user,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onLogout,
    this.isPermanent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isPermanent
            ? const Border(right: BorderSide(color: AppColors.cardBorder))
            : null,
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Attendance',
                  icon: Icons.how_to_reg_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Quiz History',
                  icon: Icons.history_edu_rounded,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'My Progress',
                  icon: Icons.trending_up_rounded,
                ),
                const Divider(height: 32, indent: 16, endIndent: 16),
                _buildSimpleItem(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  onTap: () {
                    if (!isPermanent) Navigator.pop(context);
                    // This will be handled in dashboard but we can trigger it here
                    onTabSelected(-1); // Special code for profile or similar
                  },
                ),
              ],
            ),
          ),
          _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Student',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            user?.classContext ?? 'General Class',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => onTabSelected(index),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selected: isSelected,
          selectedTileColor: AppColors.primary.withOpacity(0.1),
          leading: Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          title: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.textMuted, size: 22),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListTile(
        onTap: onLogout,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            color: AppColors.error,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
