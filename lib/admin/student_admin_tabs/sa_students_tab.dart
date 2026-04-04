import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

/// Admin tab: list, view and manage student profiles.
class SAStudentsTab extends StatefulWidget {
  const SAStudentsTab({super.key});

  @override
  State<SAStudentsTab> createState() => _SAStudentsTabState();
}

class _SAStudentsTabState extends State<SAStudentsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showStudentDetail(
      BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentDetailSheet(docId: docId, data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student Roster',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Manage all enrolled students',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.toLowerCase()),
                    style: GoogleFonts.outfit(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by name or roll number…',
                      hintStyle: GoogleFonts.outfit(
                          color: AppColors.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Student list
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: AppColors.error))),
                ),
              );
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No students enrolled yet.',
                          style: TextStyle(color: AppColors.textMuted))),
                ),
              );
            }
            var docs = snap.data!.docs.where((doc) {
              if (_query.isEmpty) return true;
              final d = doc.data() as Map<String, dynamic>;
              final name =
                  (d['name'] ?? '').toString().toLowerCase();
              final roll =
                  (d['rollNumber'] ?? '').toString().toLowerCase();
              return name.contains(_query) || roll.contains(_query);
            }).toList();

            // Sort in memory to avoid index requirements
            docs.sort((a, b) {
              final an = (a.data() as Map<String, dynamic>)['name'] ?? '';
              final bn = (b.data() as Map<String, dynamic>)['name'] ?? '';
              return an.toString().compareTo(bn.toString());
            });

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    return _StudentRow(
                      data: d,
                      onTap: () =>
                          _showStudentDetail(context, doc.id, d),
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _StudentRow({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Student';
    final roll = data['rollNumber'] ?? '';
    final grade = data['grade'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                initial,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  Text(
                    [
                      if (roll.isNotEmpty) 'Roll: $roll',
                      if (grade.isNotEmpty) 'Grade: $grade',
                    ].join(' • '),
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _StudentDetailSheet(
      {required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Student';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '';
    final grade = data['grade'] ?? '';
    final roll = data['rollNumber'] ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          if (email.isNotEmpty)
            Text(email,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                if (roll.isNotEmpty)
                  _DetailRow(
                      icon: Icons.tag_rounded,
                      label: 'Roll Number',
                      value: roll),
                if (grade.isNotEmpty)
                  _DetailRow(
                      icon: Icons.school_rounded,
                      label: 'Grade',
                      value: grade),
                if (phone.isNotEmpty)
                  _DetailRow(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: phone),

                const SizedBox(height: 16),
                Text('Fee Status (Current Month)',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _FeeSummaryRow(studentId: docId),

                // Link parent section
                const SizedBox(height: 16),
                Text('Parent Link',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _LinkParentButton(
                    studentDocId: docId, studentData: data),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeSummaryRow extends StatelessWidget {
  final String studentId;
  const _FeeSummaryRow({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fees')
          .doc(studentId)
          .collection('months')
          .doc(monthKey)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }
        
        bool exists = snap.data?.exists ?? false;
        String status = 'Pending';
        String amount = '—';
        bool isPaid = false;
        
        if (exists) {
           final d = snap.data!.data() as Map<String, dynamic>;
           status = d['status'] ?? 'Pending';
           amount = d['amount'] ?? '—';
           isPaid = status.toLowerCase() == 'paid';
        }
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPaid ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(isPaid ? Icons.check_circle_rounded : Icons.pending_rounded, color: isPaid ? AppColors.success : AppColors.warning, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATUS: ${status.toUpperCase()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: isPaid ? AppColors.success : AppColors.warning)),
                    Text('Amount: ₹$amount', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
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

class _LinkParentButton extends StatefulWidget {
  final String studentDocId;
  final Map<String, dynamic> studentData;
  const _LinkParentButton(
      {required this.studentDocId, required this.studentData});

  @override
  State<_LinkParentButton> createState() => _LinkParentButtonState();
}

class _LinkParentButtonState extends State<_LinkParentButton> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _msg;

  Future<void> _link() async {
    final parentEmail = _ctrl.text.trim();
    if (parentEmail.isEmpty) return;
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: parentEmail)
          .where('role', isEqualTo: 'parent')
          .limit(1)
          .get();
      if (q.docs.isEmpty) {
        setState(() => _msg = 'Parent account not found.');
        return;
      }
      final parentId = q.docs.first.id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentDocId)
          .update({'parentUid': parentId});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .update({'childUid': widget.studentDocId});
      setState(() => _msg = '✅ Parent linked successfully!');
    } catch (e) {
      setState(() => _msg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: "Parent's Email",
            prefixIcon: const Icon(Icons.email_rounded,
                color: AppColors.textMuted, size: 18),
            filled: true,
            fillColor: AppColors.cardLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _loading ? null : _link,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Link Parent',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        if (_msg != null) ...[
          const SizedBox(height: 8),
          Text(_msg!,
              style: GoogleFonts.outfit(
                  color: _msg!.startsWith('✅')
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 13)),
        ],
      ],
    );
  }
}
