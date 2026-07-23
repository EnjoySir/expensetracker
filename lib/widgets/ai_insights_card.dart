import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils/helpers.dart';

class AiInsightsCard extends StatelessWidget {
  const AiInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final month = provider.selectedMonth;
    final monthExpenses = provider.filteredExpenses.where((e) => e.type == 'expense').toList();
    final income = provider.getMonthlyIncomeTotal(month);
    final totalSpent = provider.getMonthlyTotal(month);

    // Calculate No-Spend Days in month
    final Set<String> spentDates = monthExpenses.map((e) => e.date).toSet();
    final now = DateTime.now();
    final int currentDay = month == Helpers.getCurrentMonth() ? now.day : 28;
    final int noSpendDays = currentDay - spentDates.length;

    // AI Tip Generation based on real spending
    String topCategory = 'None';
    double topCatAmount = 0.0;
    final breakdown = provider.getMonthlyCategoryBreakdown(month);
    if (breakdown.isNotEmpty) {
      final topEntry = breakdown.entries.reduce((a, b) => a.value > b.value ? a : b);
      topCategory = topEntry.key;
      topCatAmount = topEntry.value;
    }

    String aiTip = 'Great job tracking! Keeping daily entries helps build long-term wealth.';
    if (topCatAmount > 0) {
      aiTip = 'Your highest spending category is $topCategory (${Helpers.formatCurrency(topCatAmount)}). Setting a category budget could save you up to ${Helpers.formatCurrency(topCatAmount * 0.20)}!';
    } else if (income > 0 && totalSpent == 0) {
      aiTip = 'You have 100% savings rate so far this month! Consider depositing surplus into a Savings Goal.';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.deepPurple.shade50,
          border: Border.all(color: Colors.deepPurple.shade100, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'AI Assistant & Streak',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 11)),
                      Text(
                        '${noSpendDays > 0 ? noSpendDays : 0} No-Spend Days',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.psychology, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Smart Insight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        aiTip,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
