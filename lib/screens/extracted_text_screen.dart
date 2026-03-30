import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/quiz_provider.dart';
import '../services/api_service.dart';
import '../models/question_model.dart';

class ExtractedTextScreen extends StatefulWidget {
  const ExtractedTextScreen({super.key});

  @override
  State<ExtractedTextScreen> createState() => _ExtractedTextScreenState();
}

class _ExtractedTextScreenState extends State<ExtractedTextScreen> {
  late TextEditingController _textController;
  final ApiService _apiService = ApiService();
  bool _isParsing = false;
  bool _isGeneratingAi = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final text = context.read<QuizProvider>().extractedText;
    _textController = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── Parse via regex / backend ─────────────────────────────────────────────
  Future<void> _parseQuestions() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter or extract some text first.');
      return;
    }
    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });
    try {
      context.read<QuizProvider>().setExtractedText(text);
      List<QuestionModel> questions;
      try {
        questions = await _apiService.parseQuestions(text);
      } catch (_) {
        questions = _localParseQuestions(text);
      }
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() => _errorMessage =
            'No MCQs detected. Use A) B) C) D) Answer: X format.');
        return;
      }
      context.read<QuizProvider>().setQuestions(questions);
      await _showSaveDialog();
    } catch (e) {
      setState(() => _errorMessage = 'Parse error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  // ── Generate via Groq AI ──────────────────────────────────────────────────
  Future<void> _generateAiQuestions() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() =>
          _errorMessage = 'Please enter theory text to generate MCQs.');
      return;
    }
    setState(() {
      _isGeneratingAi = true;
      _errorMessage = null;
    });
    try {
      context.read<QuizProvider>().setExtractedText(text);
      final questions = await _apiService.generateQuestions(text);
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() => _errorMessage = 'AI failed to generate questions.');
        return;
      }
      context.read<QuizProvider>().setQuestions(questions);
      await _showSaveDialog();
    } catch (e) {
      setState(() => _errorMessage = 'AI Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGeneratingAi = false);
    }
  }

  // ── Save-to-Firestore dialog ──────────────────────────────────────────────
  Future<void> _showSaveDialog() async {
    final provider = context.read<QuizProvider>();
    final questionCount = provider.questions.length;
    final titleController = TextEditingController(
      text: 'Quiz ${DateTime.now().day}/${DateTime.now().month}',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool saving = false;
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Save Quiz',
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '$questionCount question${questionCount != 1 ? 's' : ''} ready',
                        style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Quiz Title',
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Physics Chapter 3',
                    hintStyle: GoogleFonts.outfit(
                        color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.bg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Students can find this quiz in the Mock Test screen.',
                  style: GoogleFonts.outfit(
                      color: AppColors.textMuted, fontSize: 11, height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style:
                        GoogleFonts.outfit(color: AppColors.textSecondary)),
              ),
              StatefulBuilder(
                builder: (ctx2, setSaveState) => ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(saving ? 'Saving...' : 'Save to Firestore',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  onPressed: saving
                      ? null
                      : () async {
                          setSaveState(() => saving = true);
                          try {
                            await provider.saveQuestionsToFirestore(
                                titleController.text.trim());
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) _onSaveSuccess();
                          } catch (e) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              setState(() =>
                                  _errorMessage = 'Save failed: $e');
                            }
                          }
                        },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSaveSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Quiz saved! Students can now take the mock test.',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  // ── Local regex fallback ──────────────────────────────────────────────────
  List<QuestionModel> _localParseQuestions(String text) {
    final List<QuestionModel> result = [];
    final blocks = text
        .split(RegExp(r'\n(?=\d+[\.\)]|Q\d+[\.\)])'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final block in blocks) {
      final lines = block.split('\n').map((e) => e.trim()).toList();
      if (lines.length < 5) continue;
      final question =
          lines[0].replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
      final options = <String>[];
      String answer = '';
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        final optMatch = RegExp(r'^[A-Da-d][\.\)]\s*(.+)').firstMatch(line);
        if (optMatch != null) options.add(optMatch.group(1)!.trim());
        final ansMatch = RegExp(
                r'[Aa]ns(?:wer)?\s*[:\-]?\s*([A-Da-d])',
                caseSensitive: false)
            .firstMatch(line);
        if (ansMatch != null) {
          final letter = ansMatch.group(1)!.toUpperCase();
          final idx = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
          if (idx >= 0 && idx < options.length) answer = options[idx];
        }
      }
      if (question.isNotEmpty && options.length == 4) {
        result.add(QuestionModel(
          question: question,
          options: options,
          answer: answer.isEmpty ? options[0] : answer,
        ));
      }
    }
    return result;
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Extracted Text'),
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _textController.clear(),
            icon: const Icon(Icons.clear_all_rounded,
                color: AppColors.textSecondary, size: 18),
            label: Text('Clear',
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Info bar ────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Edit text if OCR made mistakes, then Parse or use AI to generate quiz questions.',
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          // ── Text editor ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.sourceCodePro(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  height: 1.7,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintText:
                      'Extracted text appears here...\n\nOr type MCQs manually:\n\n1. Question here?\nA) Option 1\nB) Option 2\nC) Option 3\nD) Option 4\nAnswer: A',
                  hintStyle: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      height: 1.7),
                ),
              ),
            ),
          ),

          // ── Error ───────────────────────────────────────────────────────
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: GoogleFonts.outfit(
                            color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // ── Bottom actions ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              children: [
                // AI Generate button
                _ActionButton(
                  label:
                      _isGeneratingAi ? 'Thinking...' : '✨ Generate MCQs via AI',
                  gradient: AppColors.accentGradient,
                  icon: Icons.psychology_rounded,
                  isLoading: _isGeneratingAi,
                  onTap: (_isParsing || _isGeneratingAi) ? null : _generateAiQuestions,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Retry OCR
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/upload'),
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.textSecondary, size: 18),
                        label: Text('Retry OCR',
                            style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Parse Questions button
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        label: _isParsing ? 'Parsing...' : 'Parse Questions',
                        gradient: AppColors.primaryGradient,
                        icon: Icons.auto_awesome_rounded,
                        isLoading: _isParsing,
                        onTap: (_isParsing || _isGeneratingAi) ? null : _parseQuestions,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable gradient button ───────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool compact;

  const _ActionButton({
    required this.label,
    required this.gradient,
    required this.icon,
    this.isLoading = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: compact ? 13 : 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              else
                Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13 : 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
