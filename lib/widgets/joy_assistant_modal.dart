import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../database/database_helper.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../services/sound_service.dart';
import '../services/tts_service.dart';
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
  final SpeechToText _speechToText = SpeechToText();
  
  late AnimationController _pulseController;
  
  String _joyResponse = 'Hi there! I am Joy, your financial assistant. Tap the mic or type something like "What is my net worth?" or "Add \$20 for Groceries"';
  bool _isListening = false;
  bool _speechInitialized = false;

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
    
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    if (DatabaseHelper.isTesting) return;
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
            });
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechInitialized = available;
        });
        if (available) {
          _startListening();
        }
      }
    } catch (_) {}
  }

  void _startListening() async {
    if (DatabaseHelper.isTesting || !_speechInitialized) return;
    try {
      await TtsService.stop();
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _queryController.text = result.recognizedWords;
            });
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _processCommand(result.recognizedWords);
            }
          }
        },
      );
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    } catch (_) {}
  }

  void _stopListening() async {
    if (DatabaseHelper.isTesting) return;
    try {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    } catch (_) {}
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    if (!DatabaseHelper.isTesting) {
      _speechToText.stop();
      TtsService.stop();
    }
    _queryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _processCommand(String text) async {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return;

    _stopListening();
    SoundService.playClick();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final month = provider.selectedMonth;

    String response = '';

    if (query == 'hi' || query == 'hie' || query == 'hello' || query == 'hey' || query == 'hey joy' || query == 'hi joy' || query.contains('hello joy')) {
      response = 'Hey there! How can I assist you with your finances today? 😊';
    } else if (query.contains('budget') || query.contains('remaining') || query.contains('limit')) {
      final totalSpent = provider.getMonthlyTotal(month);
      final budget = provider.monthlyBudget;
      final remaining = budget - totalSpent;
      if (remaining >= 0) {
        response = 'You have ${Helpers.formatCurrency(remaining)} remaining out of your ${Helpers.formatCurrency(budget)} monthly budget! 👍';
      } else {
        response = 'You have exceeded your monthly budget by ${Helpers.formatCurrency(remaining.abs())}! ⚠️';
      }
    } else if (query.contains('net worth') ||
        query.contains('network') ||
        query.contains('net work') ||
        query.contains('networth') ||
        query.contains('net-worth') ||
        query.contains('total balance') ||
        query.contains('my balance') ||
        query.contains('wealth') ||
        query.contains('wallets')) {
      final netWorth = provider.netWorth;
      response = 'Your total Net Worth across all wallets is ${Helpers.formatCurrency(netWorth)}! 💰';
    } else if (query.contains('income') || query.contains('earned') || query.contains('salary') || query.contains('make')) {
      final totalIncome = provider.getMonthlyIncomeTotal(month);
      response = 'Your total logged income for ${Helpers.getMonthName(month)} is ${Helpers.formatCurrency(totalIncome)}. 💵';
    } else if (query.contains('spend') || query.contains('spent') || query.contains('food') || query.contains('rent') || query.contains('groceries') || query.contains('expense')) {
      final totalSpent = provider.getMonthlyTotal(month);
      final breakdown = provider.getMonthlyCategoryBreakdown(month);
      
      if (query.contains('food') || query.contains('groceries')) {
        final foodSpent = breakdown['Food & Groceries'] ?? 0.0;
        response = 'You have spent ${Helpers.formatCurrency(foodSpent)} on Food & Groceries in ${Helpers.getMonthName(month)}.';
      } else {
        response = 'You have spent ${Helpers.formatCurrency(totalSpent)} in total for ${Helpers.getMonthName(month)}.';
      }
    } else if (query.contains('saving') || query.contains('savings') || query.contains('goal')) {
      final goals = provider.savingsGoals;
      final double totalSaved = goals.fold(0.0, (sum, g) => sum + g.savedAmount);
      if (goals.isNotEmpty) {
        response = 'You have ${goals.length} active savings goals with ${Helpers.formatCurrency(totalSaved)} saved so far! 🐖';
      } else {
        response = 'You haven\'t set up any savings goals yet. You can create one in the Savings Goals tab!';
      }
    } else if (query.contains('debt') || query.contains('loan') || query.contains('owe')) {
      final debts = provider.debts;
      final borrowed = debts.where((d) => d.type == 'borrowed').fold(0.0, (s, d) => s + d.remainingBalance);
      final lent = debts.where((d) => d.type == 'lent').fold(0.0, (s, d) => s + d.remainingBalance);
      response = 'You owe ${Helpers.formatCurrency(borrowed)} in debts, and others owe you ${Helpers.formatCurrency(lent)}. 🤝';
    } else if (query.contains('bill') || query.contains('due') || query.contains('reminder')) {
      final unpaid = provider.bills.where((b) => b.isPaid == 0).toList();
      final totalUnpaid = unpaid.fold(0.0, (s, b) => s + b.amount);
      if (unpaid.isNotEmpty) {
        response = 'You have ${unpaid.length} unpaid bills totaling ${Helpers.formatCurrency(totalUnpaid)}. Check Bills in More tab! 📄';
      } else {
        response = 'All your tracked bills are marked as paid! 🎉';
      }
    } else if (query.startsWith('add') || query.contains('coffee') || query.contains('bought') || query.contains('\$')) {
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
      response = 'I understood "$text"! You can ask me about your budget, net worth, income, spending breakdown, savings goals, bills, or tell me to log transactions.';
    }

    setState(() {
      _joyResponse = response;
      _isListening = false;
    });

    TtsService.speak(response);
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
          
          // Glowing Orb Avatar for Joy (Tap to toggle mic listening)
          GestureDetector(
            onTap: _toggleListening,
            child: ScaleTransition(
              scale: _isListening
                  ? Tween<double>(begin: 0.95, end: 1.15).animate(_pulseController)
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [Colors.redAccent, Colors.purpleAccent]
                        : [Colors.purpleAccent, Colors.cyanAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isListening ? Colors.redAccent.withOpacity(0.7) : Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 42),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          const Text(
            'Hey Joy! AI Assistant',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _isListening ? '🔴 Recording voice... Tap to finish' : '🎙️ Tap microphone orb or button to speak',
            style: TextStyle(color: _isListening ? Colors.redAccent.shade100 : Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
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
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _queryController.text = suggestion;
                    _processCommand(suggestion);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic, size: 14, color: Colors.cyanAccent),
                        const SizedBox(width: 6),
                        Text(
                          suggestion,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Query Input Box with Dedicated Mic Button
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
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: _isListening ? Colors.redAccent : Colors.white.withOpacity(0.2),
                child: IconButton(
                  icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: _isListening ? Colors.white : Colors.cyanAccent, size: 22),
                  tooltip: 'Tap to speak',
                  onPressed: _toggleListening,
                ),
              ),
              const SizedBox(width: 8),
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
