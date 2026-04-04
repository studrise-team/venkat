import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

class FeesTab extends StatefulWidget {
  const FeesTab({super.key});

  @override
  State<FeesTab> createState() => _FeesTabState();
}

class _FeesTabState extends State<FeesTab> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────
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
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fee Management',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Track your monthly tuition payments',
                    style:
                        GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                _CurrentMonthCard(uid: _uid),
              ],
            ),
          ),
        ),

        // ── Payment History ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📋 Payment History',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('fees')
              .doc(_uid)
              .collection('months')
              .orderBy('month', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _EmptyCard(
                      message: 'No payment records found.',
                      icon: Icons.receipt_long_rounded),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                  return _FeeCard(data: d);
                },
                childCount: snap.data!.docs.length,
              ),
            );
          },
        ),

        // ── Upcoming Fees Alert ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: _UpcomingFeeAlert(uid: _uid),
          ),
        ),
      ],
    );
  }
}

class _CurrentMonthCard extends StatefulWidget {
  final String uid;
  const _CurrentMonthCard({required this.uid});

  @override
  State<_CurrentMonthCard> createState() => _CurrentMonthCardState();
}

class _CurrentMonthCardState extends State<_CurrentMonthCard> {
  Map<String, dynamic>? _feeData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final doc = await FirebaseFirestore.instance
        .collection('fees')
        .doc(widget.uid)
        .collection('months')
        .doc(monthKey)
        .get();
    if (mounted) {
      setState(() {
        _feeData = doc.data();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final status = _feeData?['status'] ?? 'Pending';
    final amount = _feeData?['amount'] ?? '—';
    final dueDate = _feeData?['dueDate'] ?? '—';
    final isPaid = status.toString().toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("This Month's Fee",
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 12)),
                  Text('₹$amount',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  Text('Due: $dueDate',
                      style: GoogleFonts.outfit(
                          color: Colors.white60, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'DUE',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showPaymentQR(context, amount),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Pay Now', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentQR(BuildContext context, String amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Scan to Pay', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Amount: ₹$amount', style: GoogleFonts.outfit(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=upi://pay?pa=tuition@upi&pn=AStar%20Learning&am=$amount',
                width: 200,
                height: 200,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator()));
                },
              ),
            ),
            const SizedBox(height: 28),
            Text('Scan this QR using any UPI app like GPay, PhonePe, or Paytm', 
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Simulate payment success
                      final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
                      await FirebaseFirestore.instance
                          .collection('fees')
                          .doc(widget.uid)
                          .collection('months')
                          .doc(monthKey)
                          .update({'status': 'paid', 'paidOn': DateFormat('dd MMM yyyy').format(DateTime.now())});
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment simulated successfully!'), backgroundColor: AppColors.success),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('I Have Paid', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FeeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final isPaid = status == 'paid';
    final month = data['month'] ?? '';
    final amount = data['amount'] ?? '—';
    final paidOn = data['paidOn'] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withOpacity(0.12)
                  : AppColors.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              isPaid ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              color: isPaid ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(month,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              Text(isPaid ? 'Paid on $paidOn' : 'Payment Pending',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Text(
            '₹$amount',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isPaid ? AppColors.success : AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _UpcomingFeeAlert extends StatelessWidget {
  final String uid;
  const _UpcomingFeeAlert({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.notifications_active_rounded,
            color: AppColors.warning, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fee Reminder',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(
                'Fees are due by the 5th of every month. Late payment may attract a ₹100 penalty.',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Icon(icon, size: 40, color: AppColors.textMuted),
        const SizedBox(height: 8),
        Text(message,
            style:
                GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14)),
      ]),
    );
  }
}
