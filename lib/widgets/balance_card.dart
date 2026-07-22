import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils/helpers.dart';
import '../screens/manage_accounts_screen.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final totalExpenses = provider.getMonthlyTotal(provider.selectedMonth);
    final totalIncome = provider.getMonthlyIncomeTotal(provider.selectedMonth);
    final netBalance = totalIncome - totalExpenses;
    final netWorth = provider.netWorth;
    
    final budget = provider.monthlyBudget;
    final remainingBudget = budget - totalExpenses;
    final progress = budget > 0 ? (totalExpenses / budget).clamp(0.0, 1.0) : 0.0;
    
    // Choose progress color based on usage percentage
    Color progressColor = Colors.greenAccent.shade700;
    if (totalExpenses >= budget) {
      progressColor = Colors.redAccent;
    } else if (totalExpenses >= budget * 0.8) {
      progressColor = Colors.orangeAccent;
    }

    final String worthSign = netWorth >= 0 ? '' : '-';
    final String worthText = '$worthSign${Helpers.formatCurrency(netWorth.abs())}';

    final String balanceSign = netBalance >= 0 ? '+' : '-';
    final String balanceText = '$balanceSign${Helpers.formatCurrency(netBalance.abs())}';
    final Color balanceColor = netBalance >= 0 ? Colors.greenAccent : Colors.redAccent.shade100;

    return Card(
      elevation: 4,
      shadowColor: Colors.deepPurple.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Helpers.getMonthName(provider.selectedMonth),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                        tooltip: 'Manage Wallets',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ManageAccountsScreen()),
                          ).then((_) => provider.loadAllData());
                        },
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                        tooltip: 'Set Budget',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditBudgetDialog(context, provider),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Total Net Worth (All Wallets)',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                worthText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              // Cash Flow Summary Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly Income', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('+${Helpers.formatCurrency(totalIncome)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly Expenses', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('-${Helpers.formatCurrency(totalExpenses)}', style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Net Balance', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(balanceText, style: TextStyle(color: balanceColor, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              
              Container(
                height: 1,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(vertical: 16),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBudgetStat(
                    label: 'Monthly Budget',
                    value: Helpers.formatCurrency(budget),
                  ),
                  _buildBudgetStat(
                    label: remainingBudget >= 0 ? 'Remaining Budget' : 'Over Budget',
                    value: Helpers.formatCurrency(remainingBudget.abs()),
                    valueColor: remainingBudget >= 0 ? Colors.white : Colors.redAccent.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  color: progressColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% budget used',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  if (totalExpenses > budget)
                    const Text(
                      'Budget limit exceeded!',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetStat({
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showEditBudgetDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(text: provider.monthlyBudget.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Budget Amount',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final budget = double.parse(controller.text);
                await provider.updateBudget(budget);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Budget updated to ${Helpers.formatCurrency(budget)}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
