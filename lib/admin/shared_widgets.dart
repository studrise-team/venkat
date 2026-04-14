// Shared admin form widgets used across all CRUD admin pages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Snackbar helper
// ─────────────────────────────────────────────────────────────────────────────
enum AdminSnackType { success, error, warning }

void showAdminSnackBar(
  BuildContext context,
  String message, {
  AdminSnackType type = AdminSnackType.success,
}) {
  Color color;
  IconData icon;
  if (type == AdminSnackType.error) {
    color = AppColors.error;
    icon = Icons.error_outline;
  } else if (type == AdminSnackType.warning) {
    color = const Color(0xFFFFB300);
    icon = Icons.warning_amber_rounded;
  } else {
    color = const Color(0xFF00C896);
    icon = Icons.check_circle_outline;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
}


// ─────────────────────────────────────────────────────────────────────────────
// Generic CRUD Page scaffold
// ─────────────────────────────────────────────────────────────────────────────
class AdminCrudPage extends StatelessWidget {
  final String exam;
  final String title;
  final String collection;
  final IconData icon;
  final LinearGradient gradient;
  final Widget Function(Map<String, dynamic>? data, VoidCallback onSave) formBuilder;
  final Widget Function(Map<String, dynamic> doc) cardBuilder;

  const AdminCrudPage({
    super.key,
    required this.exam,
    required this.title,
    required this.collection,
    required this.icon,
    required this.gradient,
    required this.formBuilder,
    required this.cardBuilder,
  });

  void _showForm(BuildContext context, {Map<String, dynamic>? data}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => formBuilder(data, () => Navigator.pop(context)),
    );
  }

  Future<void> _delete(BuildContext context, String docId, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Delete "$label"? This cannot be undone.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: GoogleFonts.outfit(
                      color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseService().deleteDocument(collection, docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text(exam,
                              style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showForm(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream:
                      FirebaseService().getDocumentsByExam(collection, exam),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No $title yet',
                                style: GoogleFonts.outfit(
                                    color: AppColors.textSecondary,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Tap + to add the first one',
                                style: GoogleFonts.outfit(
                                    color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = {...doc.data(), 'id': doc.id};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Stack(
                            children: [
                              cardBuilder(data),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    AdminActionBtn(
                                      icon: Icons.edit_rounded,
                                      color: AppColors.primary,
                                      onTap: () =>
                                          _showForm(context, data: data),
                                    ),
                                    const SizedBox(width: 6),
                                    AdminActionBtn(
                                      icon: Icons.delete_rounded,
                                      color: AppColors.error,
                                      onTap: () => _delete(
                                          context,
                                          doc.id,
                                          data['title'] ??
                                              data['topic'] ??
                                              'Item'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button (edit / delete)
// ─────────────────────────────────────────────────────────────────────────────
class AdminActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AdminActionBtn(
      {super.key,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet form wrapper
// ─────────────────────────────────────────────────────────────────────────────
class AdminFormSheet extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onSave;
  final List<Widget> fields;

  const AdminFormSheet({
    super.key,
    required this.title,
    required this.isLoading,
    required this.onSave,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            ...fields.map((f) =>
                Padding(padding: const EdgeInsets.only(bottom: 14), child: f)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    onTap: isLoading ? null : onSave,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading)
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                          else
                            const Icon(Icons.save_rounded,
                                color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(isLoading ? 'Saving…' : 'Save',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text field for form sheets
// ─────────────────────────────────────────────────────────────────────────────
class AdminSheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final int maxLines;

  const AdminSheetField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Button
// ─────────────────────────────────────────────────────────────────────────────
class AdminButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const AdminButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: color == null ? AppColors.primaryGradient : null,
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                  else
                    Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(label,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
