import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/quiz_provider.dart';
import '../services/ocr_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedFileName;
  File? _selectedImageFile;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  // ---- Pick PDF ----
  Future<void> _pickPdf() async {
    setState(() {
      _errorMessage = null;
      _selectedImageFile = null;
    });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedImageFile = File(result.files.single.path!);
      });
    }
  }

  // ---- Pick Image ----
  Future<void> _pickImage(ImageSource source) async {
    setState(() => _errorMessage = null);
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() {
        _selectedFileName = picked.name;
        _selectedImageFile = File(picked.path);
      });
    }
  }

  // ---- Run OCR ----
  Future<void> _runOcr() async {
    if (_selectedImageFile == null) {
      setState(
          () => _errorMessage = 'Please select an image first to run OCR.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      String text;
      if (_selectedFileName!.toLowerCase().endsWith('.pdf')) {
        text = await _ocrService.extractTextFromPdf(_selectedImageFile!);
      } else {
        text = await _ocrService.extractTextFromImage(_selectedImageFile!);
      }
      if (!mounted) return;
      context.read<QuizProvider>().setExtractedText(text);
      Navigator.pushNamed(context, '/extracted');
    } catch (e) {
      setState(() => _errorMessage = 'OCR Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Upload Questions'),
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Title ----
            Text(
              'Select Source',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload a PDF or image containing MCQs.\nOCR will extract the text automatically.',
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.6),
            ),

            const SizedBox(height: 32),

            // ---- Upload buttons ----
            Row(
              children: [
                Expanded(
                  child: _UploadButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Pick PDF',
                    color: AppColors.accentOrange,
                    onTap: _pickPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UploadButton(
                    icon: Icons.image_rounded,
                    label: 'Gallery',
                    color: AppColors.primary,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UploadButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppColors.accent,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ---- Preview ----
            if (_selectedImageFile != null && !_selectedFileName!.toLowerCase().endsWith('.pdf')) ...[
              Text(
                'Preview',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImageFile!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ---- File name chip ----
            if (_selectedFileName != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedImageFile != null
                          ? Icons.image_rounded
                          : Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedFileName = null;
                        _selectedImageFile = null;
                      }),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: GoogleFonts.outfit(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ---- OCR Button ----
            _GradientButton(
              label: _isProcessing ? 'Extracting Text...' : 'Extract Text (OCR)',
              icon: Icons.document_scanner_rounded,
              gradient: AppColors.primaryGradient,
              isLoading: _isProcessing,
              onTap: _selectedImageFile != null ? _runOcr : null,
            ),

            const SizedBox(height: 12),

            // ---- Manual entry button ----
            OutlinedButton.icon(
              onPressed: () {
                context.read<QuizProvider>().setExtractedText('');
                Navigator.pushNamed(context, '/extracted');
              },
              icon: const Icon(Icons.edit_note_rounded,
                  color: AppColors.textSecondary),
              label: Text('Enter Text Manually',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _UploadButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style:
                  GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : AppColors.card,
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
                      color: Colors.white, strokeWidth: 2),
                )
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
      ),
    );
  }
}
