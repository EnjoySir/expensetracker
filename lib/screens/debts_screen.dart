import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/debt.dart';
import '../utils/helpers.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final borrowed = provider.debts.where((d) => d.type == 'borrowed').toList();
    final lent = provider.debts.where((d) => d.type == 'lent').toList();
    final totalBorrowed = borrowed.fold(0.0, (s, d) => s + d.remainingBalance);
    final totalLent = lent.fold(0.0, (s, d) => s + d.remainingBalance);

    return Scaffold(
      appBar: AppBar(title: const Text('Debts & Loans'), backgroundColor: Colors.deepPurple),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddDebtDialog(context, provider),
      ),
      body: provider.debts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No debts or loans', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary
                Row(
                  children: [
                    Expanded(child: _summaryCard('You Owe', totalBorrowed, Colors.redAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _summaryCard('Owed to You', totalLent, Colors.green)),
                  ],
                ),
                const SizedBox(height: 20),
                if (borrowed.isNotEmpty) ...[
                  const Text('Money Borrowed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...borrowed.map((d) => _debtTile(context, provider, d)),
                  const SizedBox(height: 16),
                ],
                if (lent.isNotEmpty) ...[
                  const Text('Money Lent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...lent.map((d) => _debtTile(context, provider, d)),
                ],
              ],
            ),
    );
  }

  Widget _summaryCard(String label, double amount, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 6),
            Text(Helpers.formatCurrency(amount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _debtTile(BuildContext context, ExpenseProvider provider, Debt debt) {
    final deadline = DateTime.tryParse(debt.dueDate);
    final overdue = deadline != null && deadline.isBefore(DateTime.now()) && debt.status == 'active';
    final progress = debt.amount > 0 ? ((debt.amount - debt.remainingBalance) / debt.amount).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: debt.status == 'paid' ? Colors.green.shade100 : (overdue ? Colors.red.shade100 : Colors.orange.shade100),
          child: Icon(
            debt.status == 'paid' ? Icons.check : (debt.type == 'borrowed' ? Icons.arrow_downward : Icons.arrow_upward),
            color: debt.status == 'paid' ? Colors.green : (overdue ? Colors.red : Colors.orange),
          ),
        ),
        title: Text(debt.person, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${Helpers.formatCurrency(debt.remainingBalance)} remaining of ${Helpers.formatCurrency(debt.amount)}'),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.grey.shade200, color: Colors.deepPurple),
            ),
            const SizedBox(height: 4),
            Text(
              overdue ? 'OVERDUE - Due ${DateFormat('MMM dd').format(deadline!)}' : 'Due ${debt.dueDate}',
              style: TextStyle(fontSize: 11, color: overdue ? Colors.red : Colors.grey.shade500, fontWeight: overdue ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'pay') {
              _showPayDialog(context, provider, debt);
            } else if (value == 'paid') {
              final updated = Debt(id: debt.id, person: debt.person, amount: debt.amount, type: debt.type, dueDate: debt.dueDate, remainingBalance: 0, status: 'paid');
              await provider.updateDebt(updated);
            } else if (value == 'delete') {
              await provider.deleteDebt(debt.id!);
            }
          },
          itemBuilder: (_) => [
            if (debt.status == 'active') const PopupMenuItem(value: 'pay', child: Text('Make Payment')),
            if (debt.status == 'active') const PopupMenuItem(value: 'paid', child: Text('Mark as Paid')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, ExpenseProvider provider) {
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'borrowed';
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Debt / Loan'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'borrowed', child: Text('I Borrowed (I Owe)')),
                    DropdownMenuItem(value: 'lent', child: Text('I Lent (They Owe Me)')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: personCtrl,
                  decoration: const InputDecoration(labelText: 'Person Name', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}'),
                  tileColor: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime.now(), lastDate: DateTime(2035));
                    if (picked != null) setDialogState(() => dueDate = picked);
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
                  final amt = double.parse(amountCtrl.text);
                  final debt = Debt(person: personCtrl.text.trim(), amount: amt, type: type, dueDate: DateFormat('yyyy-MM-dd').format(dueDate), remainingBalance: amt);
                  await provider.addDebt(debt);
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayDialog(BuildContext context, ExpenseProvider provider, Debt debt) {
    final amtCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay ${debt.person}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Payment Amount (max ${Helpers.formatCurrency(debt.remainingBalance)})', border: const OutlineInputBorder()),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter amount';
              final amt = double.tryParse(v);
              if (amt == null || amt <= 0) return 'Invalid amount';
              if (amt > debt.remainingBalance) return 'Exceeds remaining balance';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final payment = double.parse(amtCtrl.text);
                final newRemaining = debt.remainingBalance - payment;
                final updated = Debt(
                  id: debt.id, person: debt.person, amount: debt.amount, type: debt.type,
                  dueDate: debt.dueDate, remainingBalance: newRemaining, status: newRemaining <= 0 ? 'paid' : 'active',
                );
                await provider.updateDebt(updated);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
