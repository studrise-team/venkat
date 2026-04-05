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
                Text('Student Management',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Manage enrolments and approvals',
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
                      hintText: 'Search by name or email…',
                      hintStyle: GoogleFonts.outfit(
                          color: AppColors.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        //Pending Approvals Section
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('isApproved', isEqualTo: false)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            final pending = snap.data!.docs;
            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${pending.length} PENDING', 
                            style: GoogleFonts.outfit(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
                        Text('Approval Requests',
                            style: GoogleFonts.outfit(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: pending.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final doc = pending[i];
                        final d = doc.data() as Map<String, dynamic>;
                        return _PendingRequestCard(
                          data: d,
                          onTap: () => _showStudentDetail(context, doc.id, d),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text('All Students',
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),

        // Student list
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )));
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
              final d = doc.data() as Map<String, dynamic>;
              if (d['isApproved'] == false) return false;

              if (_query.isEmpty) return true;
              final name = (d['name'] ?? '').toString().toLowerCase();
              final email = (d['email'] ?? '').toString().toLowerCase();
              return name.contains(_query) || email.contains(_query);
            }).toList();

            docs.sort((a, b) {
              final an = (a.data() as Map<String, dynamic>)['name'] ?? '';
              final bn = (b.data() as Map<String, dynamic>)['name'] ?? '';
              return an.toString().compareTo(bn.toString());
            });

            if (docs.isEmpty && _query.isNotEmpty) {
              return const SliverToBoxAdapter(
                child: Center(child: Text('No matching students found.')),
              );
            }

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

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _PendingRequestCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'New Student';
    final className = data['className'] ?? 'Unknown Class';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          boxShadow: [
             BoxShadow(color: AppColors.error.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              child: Text(initial, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.error)),
            ),
            const SizedBox(height: 10),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
            Text(className, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
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
    final email = data['email'] ?? '';
    final className = data['className'] ?? '';
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
                      if (email.isNotEmpty) email,
                      if (className.isNotEmpty) 'Class: $className',
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

class _StudentDetailSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _StudentDetailSheet(
      {required this.docId, required this.data});

  @override
  State<_StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<_StudentDetailSheet> {
  bool _processing = false;

  Future<void> _updateApproval(bool approve) async {
    setState(() => _processing = true);
    try {
      if (approve) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.docId)
            .update({'isApproved': true});
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student approved successfully!')),
        );
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reject Student?'),
            content: const Text('This will remove the registration request.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject', style: TextStyle(color: AppColors.error))),
            ],
          )
        );
        if (confirm == true) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.docId)
              .delete();
          if (mounted) Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _promoteStudent() async {
    final classesSnap = await FirebaseFirestore.instance.collection('academic_classes').orderBy('createdAt').get();
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Promote Student', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: classesSnap.docs.length,
            itemBuilder: (c, i) {
              final d = classesSnap.docs[i];
              return ListTile(
                title: Text(d['name'], style: GoogleFonts.outfit()),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
                    'classId': d.id,
                    'className': d['name'],
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Student promoted to ${d['name']}')));
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final name = d['name'] ?? 'Student';
    final email = d['email'] ?? '';
    final phone = d['phone'] ?? '';
    final className = d['className'] ?? 'Not Assigned';
    final isApproved = d['isApproved'] ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      if (!isApproved)
                         Container(
                           margin: const EdgeInsets.only(top: 8),
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                           decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                           child: Text('PENDING APPROVAL', style: GoogleFonts.outfit(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                         ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                _sectionHeader('Academic Info'),
                _DetailRow(icon: Icons.class_rounded, label: 'Assigned Class', value: className),
                
                const SizedBox(height: 20),
                _sectionHeader('Contact Details'),
                _DetailRow(icon: Icons.phone_rounded, label: 'Student Phone', value: phone.isNotEmpty ? phone : 'Not Specified'),
                _DetailRow(icon: Icons.email_rounded, label: 'Email Address', value: email.isNotEmpty ? email : 'Not Specified'),

                const SizedBox(height: 20),
                _sectionHeader('Account Actions'),
                if (!isApproved) ...[
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       Expanded(
                         child: _actionButton(
                           label: 'Reject',
                           color: AppColors.error,
                           onTap: () => _updateApproval(false),
                           isOutlined: true,
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: _actionButton(
                           label: 'Approve',
                           color: AppColors.success,
                           onTap: () => _updateApproval(true),
                         ),
                       ),
                     ],
                   ),
                ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            label: 'Promote Student',
                            color: AppColors.primary,
                            onTap: _promoteStudent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            label: 'Delete Student',
                            color: AppColors.error,
                            onTap: () async {
                               final confirm = await showDialog<bool>(
                                 context: context,
                                 builder: (ctx) => AlertDialog(
                                   title: const Text('Delete Student Account?'),
                                   content: const Text('This will permanently remove the student and all their data. This action cannot be undone.'),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                     TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete Permanently', style: TextStyle(color: AppColors.error))),
                                   ],
                                 )
                               );
                               if (confirm == true) {
                                  setState(() => _processing = true);
                                  await FirebaseFirestore.instance.collection('users').doc(widget.docId).delete();
                                  if (mounted) Navigator.pop(context);
                               }
                            },
                          ),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title.toUpperCase(), style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2)),
  );

  Widget _actionButton({required String label, required Color color, required VoidCallback onTap, bool isOutlined = false}) {
    return GestureDetector(
      onTap: _processing ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined ? Border.all(color: color, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: _processing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: GoogleFonts.outfit(color: isOutlined ? color : Colors.white, fontWeight: FontWeight.w700)),
      ),
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
