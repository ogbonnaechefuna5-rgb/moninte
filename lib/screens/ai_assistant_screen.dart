import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});
  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = ['How much on food?', 'Am I saving enough?', 'Biggest expense?', 'Budget insights'];

  final List<_Msg> _messages = [
    _Msg(1, 'ai', "Hi Emmanuel! I'm your financial assistant. Ask me anything about your spending, budgets, or savings.", '10:30 AM'),
  ];

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr = '${now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    setState(() {
      _messages.add(_Msg(_messages.length + 1, 'user', text, timeStr));
      _messages.add(_Msg(_messages.length + 2, 'ai',
          "You've spent ₦85,000 on food this month, which is 35% of your total spending. This is ₦15,000 under your budget of ₦60,000. Great job staying on track!",
          timeStr));
      _inputController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 0),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primaryGreen]),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 24, color: AppColors.background),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AI Assistant', style: Theme.of(context).textTheme.headlineLarge),
                  const Text('Your financial advisor', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // Suggestions
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _inputController.text = _suggestions[i],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: AppColors.surfaceDark.withValues(alpha: 0.5),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Text(_suggestions[i], style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  final isUser = m.type == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: isUser
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(m.text, style: const TextStyle(color: AppColors.background, fontSize: 14, height: 1.5)),
                                const SizedBox(height: 8),
                                Text(m.time, style: TextStyle(color: AppColors.background.withValues(alpha: 0.6), fontSize: 12)),
                              ]),
                            )
                          : GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m.text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
                                const SizedBox(height: 8),
                                Text(m.time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ]),
                            ),
                    ),
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 80),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.95),
                border: Border(top: BorderSide(color: AppColors.borderDefault)),
              ),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything about your money...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                    child: const Icon(Icons.send_rounded, size: 20, color: AppColors.background),
                  ),
                ),
              ]),
            ),
          ],
        ),
    );
  }
}

class _Msg {
  final int id;
  final String type, text, time;
  const _Msg(this.id, this.type, this.text, this.time);
}
