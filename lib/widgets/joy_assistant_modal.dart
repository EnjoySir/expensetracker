import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../services/sound_service.dart';
import '../utils/helpers.dart';

class JoyAssistantModal extends StatefulWidget {
  const JoyAssistantModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JoyAssistantModal(),
    );
  }

  @override
  State<JoyAssistantModal> createState() => _JoyAssistantModalState();
}

class _JoyAssistantModalState extends State<JoyAssistantModal> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  late AnimationController _pulseController;
  
  String _joyResponse = 'Hi there! I am Joy, your financial assistant. Say or type something like "What is my net worth?" or "Add \$20 for Groceries"';
  bool _isListening = true;

  final List<String> _voiceSuggestions = [
    'What is my net worth?',
    'How much did I spend on Food?',
    'Add \$15 for Coffee',
    'How much budget is remaining?',
    'Give me a financial tip',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _processCommand(String text) async {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return;

    SoundService.playClick();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final month = provider.selectedMonth;

    String response = '';

    if (query.contains('net worth') || query.contains('total balance') || query.contains('wallets')) {
      final netWorth = provider.netWorth;
      response = 'Your total Net Worth across all wallets is ${Helpers.formatCurrency(netWorth)}! 💰';
    } else if (query.contains('spend') || query.contains('spent') || query.contains('food') || query.contains('rent') || query.contains('groceries')) {
      final totalSpent = provider.getMonthlyTotal(month);
      final breakdown = provider.getMonthlyCategoryBreakdown(month);
      
      if (query.contains('food') || query.contains('groceries')) {
        final foodSpent = breakdown['Food & Groceries'] ?? 0.0;
        response = 'You have spent ${Helpers.formatCurrency(foodSpent)} on Food & Groceries in ${Helpers.getMonthName(month)}.';
      } else {
        response = 'You have spent ${Helpers.formatCurrency(totalSpent)} in total for ${Helpers.getMonthName(month)}.';
      }
    } else if (query.contains('budget') || query.contains('remaining')) {
      final totalSpent = provider.getMonthlyTotal(month);
      final budget = provider.monthlyBudget;
      final remaining = budget - totalSpent;
      if (remaining >= 0) {
        response = 'You have ${Helpers.formatCurrency(remaining)} remaining out of your ${Helpers.formatCurrency(budget)} monthly budget! 👍';
      } else {
        response = 'You have exceeded your monthly budget by ${Helpers.formatCurrency(remaining.abs())}! ⚠️';
      }
    } else if (query.startsWith('add') || query.contains('spent') || query.contains('coffee') || query.contains('\$')) {
      // Parse amount & add expense command
      final RegExp numRegex = RegExp(r'\$?(\d+(\.\d+)?)');
      final match = numRegex.firstMatch(query);
      if (match != null) {
        final double amount = double.tryParse(match.group(1)!) ?? 10.0;
        final int categoryId = provider.categories.first.id!;
        final int accountId = provider.accounts.isNotEmpty ? provider.accounts.first.id! : 1;

        final tx = Transaction(
          amount: amount,
          categoryId: categoryId,
          accountId: accountId,
          note: text,
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          type: 'expense',
        );

        await provider.addExpense(tx);
        await SoundService.playSuccess();
        response = 'Done! Logged a ${Helpers.formatCurrency(amount)} transaction for you. 🎉';
      } else {
        response = 'I heard you want to add a transaction! Please specify an amount (e.g. "Add \$15 for Coffee").';
      }
    } else if (query.contains('tip') || query.contains('advice') || query.contains('help')) {
      response = 'Joy\'s Smart Tip: Try saving at least 20% of your monthly income. Transferring surplus to a Savings Goal automatically builds wealth!';
    } else {
      response = 'I understood "$text"! You can ask me about your net worth, monthly budget, spending breakdown, or tell me to log transactions.';
    }

    setState(() {
      _joyResponse = response;
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Glowing Orb Avatar for Joy
          ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.1).animate(_pulseController),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.purpleAccent, Colors.cyanAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 12),
          
          const Text(
            'Hey Joy! AI Assistant',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _isListening ? 'Listening for your voice...' : 'Joy active',
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          // Response Bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              _joyResponse,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Quick Commands Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _voiceSuggestions.map((suggestion) {
              return ActionChip(
                backgroundColor: Colors.white.withOpacity(0.15),
                side: BorderSide.none,
                avatar: const Icon(Icons.mic, size: 14, color: Colors.cyanAccent),
                label: Text(
                  suggestion,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                onPressed: () {
                  _queryController.text = suggestion;
                  _processCommand(suggestion);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Query Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask Joy anything...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: _processCommand,
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.cyanAccent,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.black87, size: 20),
                  onPressed: () => _processCommand(_queryController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
