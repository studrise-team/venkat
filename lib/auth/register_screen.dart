import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _role = 'aspirant';
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  // Username check state
  bool? _usernameAvailable; // null=unchecked, true=available, false=taken
  bool _checkingUsername = false;
  Timer? _debounce;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() { _usernameAvailable = null; _checkingUsername = false; });
      return;
    }
    setState(() { _checkingUsername = true; _usernameAvailable = null; });
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final available = await AuthService().isUsernameAvailable(value.trim());
      if (mounted) {
        setState(() {
          _usernameAvailable = available;
          _checkingUsername = false;
        });
      }
    });
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || username.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_usernameAvailable == false) {
      setState(() => _error = 'Username is already taken.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService().registerUser(
        name: name,
        username: username,
        password: pass,
        role: _role,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      if (user.role == 'aspirant') {
        Navigator.pushReplacementNamed(context, '/aspirant-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Create Account',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Join Astar Learning',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          )),
                      Text('Start your exam preparation journey',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 30),

                      // Name
                      _buildLabel('Full Name'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _nameCtrl,
                        hint: 'Enter your full name',
                        icon: Icons.badge_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _buildLabel('Email Address (Optional)'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _emailCtrl,
                        hint: 'Enter your email',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildLabel('Phone Number'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _phoneCtrl,
                        hint: 'Enter your contact number',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      _buildLabel('Username'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        onChanged: _onUsernameChanged,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Choose a unique username',
                          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.alternate_email_rounded,
                              color: AppColors.textMuted, size: 20),
                          suffixIcon: _checkingUsername
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary),
                                  ),
                                )
                              : _usernameAvailable == null
                                  ? null
                                  : Icon(
                                      _usernameAvailable!
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: _usernameAvailable!
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _usernameAvailable == false
                                  ? AppColors.error
                                  : _usernameAvailable == true
                                      ? AppColors.success
                                      : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (_usernameAvailable != null && !_checkingUsername) ...[
                        const SizedBox(height: 6),
                        Text(
                          _usernameAvailable!
                              ? '✓ Username available'
                              : '✗ Username already exists',
                          style: GoogleFonts.outfit(
                            color: _usernameAvailable!
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Password
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passCtrl,
                        hint: 'At least 6 characters',
                        icon: Icons.lock_rounded,
                        obscure: _obscurePass,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      _buildLabel('Confirm Password'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _confirmCtrl,
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Role selector
                      _buildLabel('I am a…'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _RoleChip(
                            label: 'Aspirant',
                            icon: Icons.emoji_events_rounded,
                            selected: _role == 'aspirant',
                            gradient: AppColors.primaryGradient,
                            onTap: () => setState(() => _role = 'aspirant'),
                          ),
                          const SizedBox(width: 12),
                          _RoleChip(
                            label: 'Student',
                            icon: Icons.school_rounded,
                            selected: _role == 'student',
                            gradient: AppColors.accentGradient,
                            onTap: () => setState(() => _role = 'student'),
                          ),
                          const SizedBox(width: 12),
                          _RoleChip(
                            label: 'Parent',
                            icon: Icons.family_restroom_rounded,
                            selected: _role == 'parent',
                            gradient: const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFBE123C)]),
                            onTap: () => setState(() => _role = 'parent'),
                          ),
                        ],
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_error!,
                                    style: GoogleFonts.outfit(
                                        color: AppColors.error, fontSize: 13))),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _loading ? null : _register,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient:
                                _loading ? null : AppColors.primaryGradient,
                            color: _loading ? AppColors.card : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_loading)
                                const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                              else
                                const Icon(Icons.person_add_rounded,
                                    color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                  _loading ? 'Creating account…' : 'Create Account',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text('Sign In',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600));

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon,
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

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected ? gradient : null,
            color: selected ? null : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.outfit(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
