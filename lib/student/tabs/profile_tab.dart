import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/image_viewer.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final name = _userData?['name'] ?? 'Student';
    final username = _userData?['username'] ?? '';
    final phone = _userData?['phone'] ?? 'Not set';
    final email = _userData?['email'] ?? '${username}@astar.app';
    final grade = _userData?['classLevel'] ?? _userData?['grade'] ?? 'Not set';
    final school = _userData?['school'] ?? 'Not set';
    final address = _userData?['address'] ?? 'Not set';

    final joinedAt = _userData?['joinedAt'] as Timestamp?;
    final joinDate = joinedAt != null
        ? '${joinedAt.toDate().day}/${joinedAt.toDate().month}/${joinedAt.toDate().year}'
        : 'N/A';

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Text(name,
                           style: GoogleFonts.outfit(
                               color: Colors.white,
                               fontSize: 22,
                               fontWeight: FontWeight.w800)),
                     ),
                     GestureDetector(
                       onTap: () => _logout(),
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.white.withValues(alpha: 0.2),
                           borderRadius: BorderRadius.circular(10),
                         ),
                         child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                       ),
                     ),
                   ],
                ),
                Text('@$username',
                    style:
                        GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProfileBadge(icon: Icons.school_rounded, label: 'Student'),
                    const SizedBox(width: 12),
                    _ProfileBadge(
                        icon: Icons.calendar_month_rounded,
                        label: 'Since $joinDate'),
                  ],
                ),
                const SizedBox(height: 24),
                // XP Progress
                _XPProgress(xp: _userData?['xp'] ?? 0),
              ],
            ),
          ),
        ),

        // ── Info Section ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📋 Personal Info',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'Full Name',
                      value: name),
                  _InfoDivider(),
                  _InfoRow(
                      icon: Icons.school_rounded,
                      label: 'School / College',
                      value: school),
                  _InfoDivider(),
                  _InfoRow(
                      icon: Icons.class_rounded,
                      label: 'Grade / Class',
                      value: grade),
                  _InfoDivider(),
                  _InfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: phone),
                  _InfoDivider(),
                  _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: address),
                ],
              ),
            ),
          ),
        ),

        // ── Certificates Vault ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🏆 My Certificates',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: () => _uploadCertificate(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Upload',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _CertificatesSection(uid: _uid)),

        // ── Edit Profile ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('⚙️ Settings',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.edit_rounded,
                  label: 'Edit Profile',
                  onTap: () => _showEditProfile(),
                ),
                const SizedBox(height: 10),
                _SettingTile(
                  icon: Icons.lock_rounded,
                  label: 'Change Password',
                  onTap: () => _showChangePassword(),
                ),
                const SizedBox(height: 10),
                _SettingTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: AppColors.error,
                  onTap: () => _logout(),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  void _uploadCertificate() async {
    final titleCtrl = TextEditingController();
    final picker = ImagePicker();
    XFile? pickedImg;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Upload Certificate', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setModalState(() => pickedImg = img);
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                    child: pickedImg != null 
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(pickedImg!.path), fit: BoxFit.cover))
                      : const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: 'Certificate Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: uploading ? null : () async {
                    if (titleCtrl.text.isEmpty || pickedImg == null) return;
                    setModalState(() => uploading = true);
                    final url = await CloudinaryService().uploadFile(File(pickedImg!.path), folder: 'certificates');
                    if (url != null) {
                      await FirebaseFirestore.instance.collection('certificates').doc(_uid).collection('items').add({
                        'title': titleCtrl.text.trim(),
                        'imageUrl': url,
                        'verified': false,
                        'addedAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: uploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Save Certificate', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _userData?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _userData?['phone'] ?? '');
    final gradeCtrl = TextEditingController(text: _userData?['grade'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Profile',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon:
                    const Icon(Icons.person_rounded, color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon:
                    const Icon(Icons.phone_rounded, color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gradeCtrl,
              decoration: InputDecoration(
                labelText: 'Grade / Class',
                prefixIcon:
                    const Icon(Icons.class_rounded, color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .update({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'grade': gradeCtrl.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile updated!',
                          style: GoogleFonts.outfit()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('Save Changes',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Change Password',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon:
                    const Icon(Icons.lock_rounded, color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password (6+ chars)',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final cred = EmailAuthProvider.credential(
                    email: user?.email ?? '',
                    password: currentCtrl.text,
                  );
                  await user?.reauthenticateWithCredential(cred);
                  await user?.updatePassword(newCtrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password changed successfully!',
                            style: GoogleFonts.outfit()),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e', style: GoogleFonts.outfit()),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('Update Password',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout',
                style: GoogleFonts.outfit(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

// ── Sub-Widgets ──────────────────────────────────────────────────────────────

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ProfileBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.textMuted)),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 0, indent: 48, color: AppColors.cardBorder);
  }
}

class _CertificatesSection extends StatelessWidget {
  final String uid;
  const _CertificatesSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('certificates')
          .doc(uid)
          .collection('items')
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
           return const SizedBox.shrink();
        }
        final docs = snap.data!.docs;
        return SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final verified = d['verified'] ?? false;
              return Container(
                width: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (d['imageUrl'] != null) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(imageUrl: d['imageUrl'], title: d['title'] ?? 'Certificate')
                          ));
                        }
                      },
                      child: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(10),
                          image: d['imageUrl'] != null ? DecorationImage(image: NetworkImage(d['imageUrl']), fit: BoxFit.cover) : null,
                        ),
                        child: d['imageUrl'] == null ? Icon(Icons.workspace_premium_rounded, color: verified ? AppColors.primary : AppColors.textMuted) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(d['title'] ?? (d['name'] ?? 'Certificate'), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(verified ? Icons.verified_rounded : Icons.pending_rounded, size: 12, color: verified ? AppColors.success : AppColors.warning),
                              const SizedBox(width: 4),
                              Text(verified ? 'Verified' : 'Pending', 
                                style: GoogleFonts.outfit(fontSize: 10, color: verified ? AppColors.success : AppColors.warning, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: tileColor, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.outfit(
                    color: tileColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _XPProgress extends StatelessWidget {
  final int xp;
  const _XPProgress({required this.xp});

  @override
  Widget build(BuildContext context) {
    // Level = XP / 500 + 1
    final xpVal = (xp is int) ? xp : (xp as num).toInt();
    final level = (xpVal / 500).floor() + 1;
    final xpInCurrentLevel = xpVal % 500;
    final progress = xpInCurrentLevel / 500;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level $level', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$xpVal XP', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text('Next Level: ${500 - xpInCurrentLevel} XP left', 
          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}
