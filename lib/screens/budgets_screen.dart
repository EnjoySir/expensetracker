import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/budget.dart';
import '../utils/color_helper.dart';
import '../utils/helpers.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final budgets = provider.budgets;

    return Scaffold(
      appBar: AppBar(title: const Text('Category Budgets'), backgroundColor: Colors.deepPurple),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddBudgetDialog(context, provider),
      ),
      body: budgets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No category budgets set', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text('Tap + to set spending limits', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final spent = provider.getCategoryMonthlyTotal(budget.categoryId, provider.selectedMonth);
                final remaining = budget.amountLimit - spent;
                final progress = budget.amountLimit > 0 ? (spent / budget.amountLimit).clamp(0.0, 1.0) : 0.0;
                final color = ColorHelper.fromHex(budget.categoryColor ?? '9E9E9E');

                Color barColor = Colors.green;
                if (spent >= budget.amountLimit) {
                  barColor = Colors.red;
                } else if (spent >= budget.amountLimit * 0.8) {
                  barColor = Colors.orange;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(budget.categoryIcon ?? '📌', style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(budget.categoryName ?? 'Category', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async => await provider.deleteBudget(budget.id!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spent: ${Helpers.formatCurrency(spent)}', style: TextStyle(color: Colors.grey.shade700)),
                            Text('Limit: ${Helpers.formatCurrency(budget.amountLimit)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey.shade200, color: barColor),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(progress * 100).toStringAsFixed(0)}% used', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            Text(
                              remaining >= 0 ? '${Helpers.formatCurrency(remaining)} left' : '${Helpers.formatCurrency(remaining.abs())} over!',
                              style: TextStyle(fontSize: 11, color: remaining >= 0 ? Colors.grey.shade600 : Colors.red, fontWeight: remaining >= 0 ? FontWeight.normal : FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, ExpenseProvider provider) {
    int? categoryId;
    final amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Filter out categories that already have budgets
    final existingCatIds = provider.budgets.map((b) => b.categoryId).toSet();
    final availableCategories = provider.categories.where((c) => !existingCatIds.contains(c.id)).toList();

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All categories already have budgets assigned')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Category Budget'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: categoryId,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: availableCategories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'));
                }).toList(),
                onChanged: (v) => categoryId = v,
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monthly Limit', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid amount';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final budget = Budget(categoryId: categoryId!, amountLimit: double.parse(amountCtrl.text));
                await provider.addBudget(budget);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Set Budget', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
