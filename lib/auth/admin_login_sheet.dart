import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/auth_service.dart';

class AdminLoginSheet extends StatefulWidget {
  const AdminLoginSheet({super.key});

  @override
  State<AdminLoginSheet> createState() => _AdminLoginSheetState();
}

class _AdminLoginSheetState extends State<AdminLoginSheet> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter admin password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().loginAdmin(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final profile = await AuthService().getCurrentUserProfile();
      if (!mounted) return;
      
      if (profile != null && profile.role == 'admin') {
        Navigator.pop(context); // close sheet
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        await AuthService().signOut();
        setState(() => _error = 'This account does not have admin privileges.');
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Admin Login',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailCtrl,
            style: GoogleFonts.outfit(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Admin Email Route',
              labelText: 'Admin Email',
              prefixIcon: const Icon(Icons.email_rounded, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: GoogleFonts.outfit(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _login(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          _GradientBtn(
            label: _loading ? 'Signing in…' : 'Sign In as Admin',
            icon: Icons.login_rounded,
            isLoading: _loading,
            onTap: _login,
          ),
        ],
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  const _GradientBtn({required this.label, required this.icon,
      required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
