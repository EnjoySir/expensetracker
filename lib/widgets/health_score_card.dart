import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils/helpers.dart';

class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final month = provider.selectedMonth;
    final income = provider.getMonthlyIncomeTotal(month);
    final expenses = provider.getMonthlyTotal(month);
    final budget = provider.monthlyBudget;

    // Calculations
    final double netSavings = income - expenses;
    final double savingsRate = income > 0 ? ((netSavings / income) * 100).clamp(0.0, 100.0) : 0.0;
    final double budgetUsagePct = budget > 0 ? ((expenses / budget) * 100).clamp(0.0, 100.0) : 0.0;

    // Health score algorithm (0 - 100)
    double score = 50.0; // Base score
    if (savingsRate >= 20) score += 30;
    else if (savingsRate > 0) score += (savingsRate / 20) * 30;

    if (budgetUsagePct <= 80) score += 20;
    else if (budgetUsagePct <= 100) score += 10;
    else score -= 15;

    score = score.clamp(0.0, 100.0);

    String statusText = 'Needs Attention';
    Color statusColor = Colors.orangeAccent;
    IconData statusIcon = Icons.warning_amber_rounded;

    if (score >= 80) {
      statusText = 'Excellent';
      statusColor = Colors.greenAccent.shade700;
      statusIcon = Icons.stars_rounded;
    } else if (score >= 60) {
      statusText = 'Good';
      statusColor = Colors.blueAccent;
      statusIcon = Icons.thumb_up_rounded;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Financial Health Score',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Score Gauge Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.white12,
                        color: statusColor,
                        strokeWidth: 8,
                      ),
                    ),
                    Text(
                      '${score.toInt()}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                
                // Insights Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings Rate: ${savingsRate.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        income > 0
                            ? 'Saved ${Helpers.formatCurrency(netSavings > 0 ? netSavings : 0)} this month'
                            : 'No income logged for this month yet',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Budget Usage: ${budgetUsagePct.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expenses <= budget
                            ? '${Helpers.formatCurrency(budget - expenses)} remaining in budget'
                            : 'Exceeded budget by ${Helpers.formatCurrency(expenses - budget)}',
                        style: TextStyle(
                          color: expenses <= budget ? Colors.white70 : Colors.redAccent.shade100,
                          fontSize: 11,
                        ),
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
