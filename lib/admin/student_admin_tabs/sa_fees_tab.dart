import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../services/fees_service.dart';
import '../../services/auth_service.dart';

/// Admin tab: record and manage fee payments for students.
class SAFeesTab extends StatefulWidget {
  const SAFeesTab({super.key});

  @override
  State<SAFeesTab> createState() => _SAFeesTabState();
}

class _SAFeesTabState extends State<SAFeesTab> {
  DateTime _selectedDate = DateTime.now();

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedDate);

  void _pickMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      // We only care about the month/year but showDatePicker needs a full date
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _showSetStandardFeeDialog(BuildContext context) async {
    final currentFee = await FeesService().getStandardFee();
    final ctrl = TextEditingController(text: currentFee.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Standard Monthly Fee', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Amount (₹)',
            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FeesService().setStandardFee(double.tryParse(ctrl.text) ?? 2000.0);
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Standard fee updated!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendReminders() async {
    await FeesService().sendFeeReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fee reminders sent to all pending students!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showUpdateFeeDialog(BuildContext context, String studentId, String studentName, String currentStatus, String currentAmount) async {
    final standardFee = await FeesService().getStandardFee();
    String newStatus = currentStatus.toLowerCase() == 'paid' ? 'paid' : 'pending';
    final amountCtrl = TextEditingController(text: currentAmount == '—' ? standardFee.toInt().toString() : currentAmount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Update Fee Status', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Student: $studentName | ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: 'Payable Amount (₹)',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.textMuted, size: 18),
                              filled: true,
                              fillColor: AppColors.cardLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final val = int.tryParse(amountCtrl.text) ?? 0;
                                setModalState(() => amountCtrl.text = (val + 100).toString());
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.add_rounded, color: AppColors.success, size: 20),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                final val = int.tryParse(amountCtrl.text) ?? 0;
                                if (val >= 100) setModalState(() => amountCtrl.text = (val - 100).toString());
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.remove_rounded, color: AppColors.error, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Text('Payment Status', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => newStatus = 'paid'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: newStatus == 'paid' ? AppColors.success : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: newStatus == 'paid' ? Colors.transparent : AppColors.cardBorder),
                              ),
                              alignment: Alignment.center,
                              child: Text('PAID', style: GoogleFonts.outfit(color: newStatus == 'paid' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => newStatus = 'pending'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: newStatus == 'pending' ? AppColors.warning : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: newStatus == 'pending' ? Colors.transparent : AppColors.cardBorder),
                              ),
                              alignment: Alignment.center,
                              child: Text('PENDING', style: GoogleFonts.outfit(color: newStatus == 'pending' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    
                    GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('fees')
                            .doc(studentId)
                            .collection('months')
                            .doc(_monthKey)
                            .set({
                          'month': DateFormat('MMMM yyyy').format(_selectedDate),
                          'status': newStatus,
                          'amount': amountCtrl.text.trim(),
                          'dueDate': '5th ${DateFormat('MMMM').format(DateTime(_selectedDate.year, _selectedDate.month + 1, 1))}',
                          'paidOn': newStatus == 'paid' ? DateFormat('dd MMM yyyy').format(DateTime.now()) : '',
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                        
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: Text('Save Payment Record', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fee Management',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                        Text('Track monthly payments',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showSetStandardFeeDialog(context),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickMonth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(DateFormat('MMMM yyyy').format(_selectedDate),
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendReminders,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            }
            if (snap.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No students found.', style: TextStyle(color: AppColors.textMuted))),
                ),
              );
            }
            final docs = snap.data!.docs.toList();
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
                    final student = docs[i];
                    final sData = student.data() as Map<String, dynamic>;
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('fees')
                          .doc(student.id)
                          .collection('months')
                          .doc(_monthKey)
                          .get(),
                      builder: (context, feeSnap) {
                        String status = 'pending';
                        String amount = '—';
                        if (feeSnap.hasData && feeSnap.data!.exists) {
                          final fData = feeSnap.data!.data() as Map<String, dynamic>;
                          status = fData['status']?.toString().toLowerCase() ?? 'pending';
                          amount = fData['amount']?.toString() ?? '—';
                        }
                        
                        final isPaid = status == 'paid';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.cardBorder),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  sData['name']?.substring(0, 1).toUpperCase() ?? 'S',
                                  style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sData['name'] ?? 'Student', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    if ((sData['rollNumber'] ?? '').isNotEmpty)
                                      Text('Roll: ${sData['rollNumber']}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(isPaid ? 'PAID' : 'PENDING', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: isPaid ? AppColors.success : AppColors.warning)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(amount == '—' ? '₹—' : '₹$amount', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                                onPressed: () => _showUpdateFeeDialog(context, student.id, sData['name'] ?? 'Student', status, amount),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}
