import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _loading = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _classCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.user.email ?? '');
    _classCtrl = TextEditingController(text: widget.user.classContext ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _classCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final updatedData = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'classContext': _classCtrl.text.trim(),
      };

      await AuthService().updateUserProfile(widget.user.uid, updatedData);
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text('Delete Account?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Warning: If you delete the account, the data completely arriase cant backup after. Are you sure you want to proceed?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete Permanently', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        await AuthService().deleteUserAccount(widget.user.uid);
        if (mounted) {
          // Firebase auto-signs out on delete, but we pop to ensure UI reset
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isStudent = widget.user.role == 'student';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile', 
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Header
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: isStudent ? AppColors.accentGradient : AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isStudent ? AppColors.accent : AppColors.primary).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 50),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isStudent ? AppColors.accent : AppColors.primary,
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.user.username, 
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14, letterSpacing: 1.2)),
            const SizedBox(height: 32),

            // Profile Fields
            _buildField(
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              controller: _nameCtrl,
              isEditing: _isEditing,
            ),
            _buildField(
              label: 'Phone Number',
              icon: Icons.phone_android_rounded,
              controller: _phoneCtrl,
              isEditing: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            
            // Email (Optional - only show if exists or if editing)
            if (_isEditing || (widget.user.email != null && widget.user.email!.isNotEmpty))
              _buildField(
                label: 'Email Address',
                icon: Icons.alternate_email_rounded,
                controller: _emailCtrl,
                isEditing: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),

            // Class (Student Only)
            if (isStudent)
              _buildField(
                label: 'Class / Context',
                icon: Icons.school_outlined,
                controller: _classCtrl,
                isEditing: _isEditing,
              ),

            const SizedBox(height: 40),

            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isStudent ? AppColors.accent : AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Save Changes', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 48),
            
            // Delete Account Section
            if (!_isEditing) ...[
              const Divider(color: AppColors.cardBorder),
              const SizedBox(height: 24),
              Text(
                'Danger Zone',
                style: GoogleFonts.outfit(
                  color: AppColors.error.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _loading ? null : _confirmDeleteAccount,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account',
                              style: GoogleFonts.outfit(
                                color: AppColors.error,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Permanently remove all your data',
                              style: GoogleFonts.outfit(
                                color: AppColors.error.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.error.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          if (isEditing)
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: widget.user.role == 'student' ? AppColors.accent : AppColors.primary, size: 20),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: widget.user.role == 'student' ? AppColors.accent : AppColors.primary, width: 1.5),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Not set' : controller.text,
                      style: GoogleFonts.outfit(
                        color: controller.text.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
