import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../auth/admin_login_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;



  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService().loginUser(
        username: username,
        password: password,
      );
      if (!mounted) return;
      
      // Navigate based on user role
      if (user.role == 'admin') {
         Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (user.role == 'student') {
         Navigator.pushReplacementNamed(context, '/student-dashboard');
      } else {
         Navigator.pushReplacementNamed(context, '/aspirant-dashboard');
      }
    } on Exception catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('invalid-credential') ||
          msg.contains('user-not-found') ||
          msg.contains('wrong-password')) {
        msg = 'Invalid username or password.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAdminLogin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminLoginSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // ── Top bar ──────────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Astar Learning',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.textPrimary,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      )),
                                  Text('Your success partner',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      )),
                                ],
                              ),
                              GestureDetector(
                                onTap: _showAdminLogin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.admin_panel_settings_rounded,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text('Admin',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Logo ─────────────────────────────────────────────────────
                        SizedBox(
                          height: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                          ),
                        ),

                        // This pushes everything below to the bottom/middle!
                        const Spacer(),

                        const SizedBox(height: 10),

                        // ── Form (Animated & Modern) ──────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 40 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface, // Clean card inside the gradient background
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.cardBorder, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Welcome Back',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enter your details to sign in',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  _InputField(
                                    controller: _usernameCtrl,
                                    label: 'User ID / Username',
                                    icon: Icons.person_rounded,
                                    onChanged: (_) => setState(() => _error = null),
                                  ),
                                  const SizedBox(height: 14),
                                  _InputField(
                                    controller: _passCtrl,
                                    label: 'Password',
                                    icon: Icons.lock_rounded,
                                    obscure: _obscure,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: AppColors.textMuted,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    onChanged: (_) => setState(() => _error = null),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 14),
                                    _ErrorBanner(message: _error!),
                                  ],
                                  const SizedBox(height: 24),
                                  _GradientButton(
                                    label: _loading ? 'Signing in…' : 'Sign In',
                                    icon: Icons.login_rounded,
                                    isLoading: _loading,
                                    onTap: _login,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Don't have an account? ",
                                          style: GoogleFonts.outfit(
                                              color: AppColors.textSecondary,
                                              fontSize: 14)),
                                      GestureDetector(
                                        onTap: () =>
                                            Navigator.pushNamed(context, '/register'),
                                        child: Text('Register',
                                            style: GoogleFonts.outfit(
                                              color: AppColors.primary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            )),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ───────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: GoogleFonts.outfit(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon,
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
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13))),
      ]),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  const _GradientButton(
      {required this.label,
      required this.icon,
      required this.isLoading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.primaryGradient,
          color: isLoading ? AppColors.card : null,
          borderRadius: BorderRadius.circular(14),
        ),
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
    );
  }
}
