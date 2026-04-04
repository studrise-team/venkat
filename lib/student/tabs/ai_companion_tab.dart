import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/ai_service.dart';

class AICompanionTab extends StatefulWidget {
  const AICompanionTab({super.key});

  @override
  State<AICompanionTab> createState() => _AICompanionTabState();
}

class _AICompanionTabState extends State<AICompanionTab> {
  final _inputCtrl = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: "Hello! I am your Astar AI Study Partner. 🚀\nHow can I help you today? You can ask me to explain topics, solve math problems, or quiz you on your subjects.",
      isAI: true,
    ),
  ];
  bool _isTyping = false;

  void _handleSend() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isAI: false));
      _inputCtrl.clear();
      _isTyping = true;
    });

    final response = await AIService().askAI(text);
    
    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: response,
          isAI: true,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('AI Study Partner',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Your 24/7 personal tutor for all subjects',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),

        // Chat Area
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (context, i) => _messages[i],
          ),
        ),

        if (_isTyping)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Row(
              children: [
                Text('Astar AI is thinking...', 
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

        // Input Area
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _inputCtrl,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String text;
  final bool isAI;

  const _ChatMessage({required this.text, required this.isAI});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAI ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAI ? 4 : 16),
            bottomRight: Radius.circular(isAI ? 16 : 4),
          ),
          border: isAI ? Border.all(color: AppColors.cardBorder) : null,
          boxShadow: [
            if (isAI)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isAI ? AppColors.textPrimary : Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
