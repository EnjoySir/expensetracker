import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/bill.dart';
import '../utils/helpers.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final bills = provider.bills;
    final unpaid = bills.where((b) => b.isPaid == 0).toList();
    final paid = bills.where((b) => b.isPaid == 1).toList();
    final totalUnpaid = unpaid.fold(0.0, (s, b) => s + b.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Bills & Reminders'), backgroundColor: Colors.deepPurple),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddBillDialog(context, provider),
      ),
      body: bills.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No bills tracked yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Card
                Card(
                  color: Colors.deepPurple.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Unpaid Bills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${unpaid.length} bills remaining', style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                        Text(
                          Helpers.formatCurrency(totalUnpaid),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (unpaid.isNotEmpty) ...[
                  const Text('Upcoming / Due', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...unpaid.map((b) => _billTile(context, provider, b)),
                  const SizedBox(height: 16),
                ],
                if (paid.isNotEmpty) ...[
                  Text('Paid (${paid.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  ...paid.map((b) => _billTile(context, provider, b)),
                ],
              ],
            ),
    );
  }

  Widget _billTile(BuildContext context, ExpenseProvider provider, Bill bill) {
    final deadline = DateTime.tryParse(bill.dueDate);
    final now = DateTime.now();
    final overdue = deadline != null && deadline.isBefore(now) && bill.isPaid == 0;
    final dueToday = deadline != null && deadline.year == now.year && deadline.month == now.month && deadline.day == now.day;
    final dueTomorrow = deadline != null && deadline.difference(now).inDays == 1;

    String statusText = '';
    Color statusColor = Colors.grey;
    if (bill.isPaid == 1) {
      statusText = '✅ Paid';
      statusColor = Colors.green;
    } else if (overdue) {
      statusText = '⚠️ Overdue';
      statusColor = Colors.red;
    } else if (dueToday) {
      statusText = '🔔 Due Today';
      statusColor = Colors.orange;
    } else if (dueTomorrow) {
      statusText = '📢 Due Tomorrow';
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: bill.isPaid == 1 ? Colors.green.shade100 : (overdue ? Colors.red.shade100 : Colors.deepPurple.shade100),
          child: Text(bill.categoryIcon ?? '📄', style: const TextStyle(fontSize: 18)),
        ),
        title: Text(bill.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${Helpers.formatCurrency(bill.amount)} • Due ${bill.dueDate}'),
            if (statusText.isNotEmpty)
              Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bill.isPaid == 0)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                tooltip: 'Mark as Paid',
                onPressed: () async {
                  final updated = Bill(
                    id: bill.id, name: bill.name, amount: bill.amount,
                    dueDate: bill.dueDate, categoryId: bill.categoryId, isPaid: 1,
                  );
                  await provider.updateBill(updated);
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () async {
                await provider.deleteBill(bill.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBillDialog(BuildContext context, ExpenseProvider provider) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    int? categoryId;
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Bill'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Bill Name (e.g. Electricity)', border: OutlineInputBorder()),
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
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: provider.categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => categoryId = v),
                  validator: (v) => v == null ? 'Select category' : null,
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
                  final bill = Bill(
                    name: nameCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text),
                    dueDate: DateFormat('yyyy-MM-dd').format(dueDate),
                    categoryId: categoryId!,
                  );
                  await provider.addBill(bill);
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
}
