import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/savings_goal.dart';
import '../utils/helpers.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final goals = provider.savingsGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddGoalDialog(context, provider),
      ),
      body: goals.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No savings goals yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text('Tap + to create one', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = goal.targetAmount > 0
                    ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
                    : 0.0;
                final remaining = goal.targetAmount - goal.savedAmount;
                final deadline = DateTime.tryParse(goal.deadline);
                final daysLeft = deadline != null ? deadline.difference(DateTime.now()).inDays : 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(goal.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'add') {
                                  _showAddFundsDialog(context, provider, goal);
                                } else if (value == 'delete') {
                                  await provider.deleteSavingsGoal(goal.id!);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'add', child: Text('Add Funds')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Saved: ${Helpers.formatCurrency(goal.savedAmount)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                            Text('Target: ${Helpers.formatCurrency(goal.targetAmount)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            color: progress >= 1.0 ? Colors.green : Colors.deepPurple,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(progress * 100).toStringAsFixed(1)}% complete', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(
                              remaining > 0 ? '${Helpers.formatCurrency(remaining)} to go' : '🎉 Goal reached!',
                              style: TextStyle(fontSize: 12, color: remaining > 0 ? Colors.grey.shade600 : Colors.green, fontWeight: remaining > 0 ? FontWeight.normal : FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (deadline != null)
                          Text(
                            daysLeft > 0 ? '$daysLeft days remaining (${DateFormat('MMM dd, yyyy').format(deadline)})' : 'Deadline passed',
                            style: TextStyle(fontSize: 11, color: daysLeft > 0 ? Colors.grey.shade500 : Colors.red),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddGoalDialog(BuildContext context, ExpenseProvider provider) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 90));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Savings Goal'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Goal Name (e.g. Emergency Fund)', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Target Amount', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Deadline'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(deadline)),
                  tileColor: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: deadline, firstDate: DateTime.now(), lastDate: DateTime(2035));
                    if (picked != null) setDialogState(() => deadline = picked);
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
                  final goal = SavingsGoal(
                    name: nameCtrl.text.trim(),
                    targetAmount: double.parse(targetCtrl.text),
                    deadline: DateFormat('yyyy-MM-dd').format(deadline),
                  );
                  await provider.addSavingsGoal(goal);
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, ExpenseProvider provider, SavingsGoal goal) {
    final amtCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Funds to "${goal.name}"'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter amount';
              if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid amount';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updated = SavingsGoal(
                  id: goal.id,
                  name: goal.name,
                  targetAmount: goal.targetAmount,
                  savedAmount: goal.savedAmount + double.parse(amtCtrl.text),
                  deadline: goal.deadline,
                );
                await provider.updateSavingsGoal(updated);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${Helpers.formatCurrency(double.parse(amtCtrl.text))} to ${goal.name}'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
