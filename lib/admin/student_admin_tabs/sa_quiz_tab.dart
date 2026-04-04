import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/quiz_provider.dart';

/// Admin tab: Create and manage daily quizzes for students.
class SAQuizTab extends StatefulWidget {
  const SAQuizTab({super.key});

  @override
  State<SAQuizTab> createState() => _SAQuizTabState();
}

class _SAQuizTabState extends State<SAQuizTab> {
  void _startQuizCreation() {
    context.read<QuizProvider>().setExamContext('Student Daily Quiz', collection: 'student_quizzes');
    context.read<QuizProvider>().reset();
    Navigator.pushNamed(context, '/upload');
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz Management',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Manage daily quizzes for students',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _startQuizCreation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Create Quiz',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('student_quizzes')
              .where('forRole', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            }
            if (snap.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No quizzes created yet.', style: TextStyle(color: AppColors.textMuted))),
                ),
              );
            }
            
            final docs = snap.data!.docs.toList();
            docs.sort((a, b) {
              final at = (a.data() as Map<String, dynamic>)['createdAt'] ?? 0;
              final bt = (b.data() as Map<String, dynamic>)['createdAt'] ?? 0;
              return bt.toString().compareTo(at.toString()); // descending
            });
            
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final bool isActive = d['isActive'] ?? true;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.textMuted.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(isActive ? 'ACTIVE' : 'INACTIVE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? AppColors.success : AppColors.textSecondary)),
                              ),
                              Switch(
                                value: isActive,
                                activeColor: AppColors.accent,
                                onChanged: (val) {
                                  FirebaseFirestore.instance.collection('student_quizzes').doc(doc.id).update({'isActive': val});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(d['title'] ?? 'Quiz', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                          if ((d['description'] ?? '').isNotEmpty)
                            Text(d['description'], style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => FirebaseFirestore.instance.collection('student_quizzes').doc(doc.id).delete(),
                                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  context.read<QuizProvider>().setExamContext('Student Daily Quiz', collection: 'student_quizzes');
                                  Navigator.pushNamed(context, '/upload');
                                },
                                child: Text('Add Questions', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AdminManageQuestionsScreen extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const _AdminManageQuestionsScreen({required this.quizId, required this.quizData});

  @override
  State<_AdminManageQuestionsScreen> createState() => _AdminManageQuestionsScreenState();
}

class _AdminManageQuestionsScreenState extends State<_AdminManageQuestionsScreen> {
  void _showAddQuestionDialog() {
    final qCtrl = TextEditingController();
    final opt1Ctrl = TextEditingController();
    final opt2Ctrl = TextEditingController();
    final opt3Ctrl = TextEditingController();
    final opt4Ctrl = TextEditingController();
    int correctIndex = 0;

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Question',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: qCtrl,
                        maxLines: 2,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Question text',
                          filled: true,
                          fillColor: AppColors.cardLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(4, (i) {
                        final ctrls = [opt1Ctrl, opt2Ctrl, opt3Ctrl, opt4Ctrl];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: correctIndex,
                                activeColor: AppColors.primary,
                                onChanged: (val) => setModalState(() => correctIndex = val!),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: ctrls[i],
                                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'Option ${i + 1}',
                                    filled: true,
                                    fillColor: AppColors.cardLight,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          if (qCtrl.text.isEmpty || opt1Ctrl.text.isEmpty || opt2Ctrl.text.isEmpty) return;
                          final options = [opt1Ctrl.text.trim(), opt2Ctrl.text.trim(), opt3Ctrl.text.trim(), opt4Ctrl.text.trim()].where((e) => e.isNotEmpty).toList();
                          if (correctIndex >= options.length) correctIndex = 0;
                          
                          final newQ = {
                            'question': qCtrl.text.trim(),
                            'options': options,
                            'correctAnswer': correctIndex,
                            'answer': options[correctIndex],
                          };
                          await FirebaseFirestore.instance.collection('student_quizzes').doc(widget.quizId).update({
                            'questions': FieldValue.arrayUnion([newQ])
                          });
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text('Save Question', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.quizData['title'] ?? 'Manage Questions', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('student_quizzes').doc(widget.quizId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>?;
          final questions = List<Map<String, dynamic>>.from(data?['questions'] ?? []);

          if (questions.isEmpty) {
            return const Center(child: Text('No questions added yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final q = questions[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q${i + 1}: ${q['question']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...(q['options'] as List).asMap().entries.map((entry) {
                      final isCorrect = entry.key == q['correctAnswer'];
                      return Text(
                        '${entry.key + 1}. ${entry.value} ${isCorrect ? '✅' : ''}',
                        style: GoogleFonts.outfit(color: isCorrect ? AppColors.success : AppColors.textSecondary),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
