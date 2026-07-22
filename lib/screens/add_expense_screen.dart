import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../services/sound_service.dart';
import '../utils/helpers.dart';
import '../widgets/category_chip.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _merchantController = TextEditingController();
  final _locationController = TextEditingController();
  
  int? _selectedCategoryId;
  int? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'expense';
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (provider.accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = provider.accounts.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'expense'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'expense' ? Colors.redAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Expense',
                    style: TextStyle(
                      color: _selectedType == 'expense' ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'income'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'income' ? Colors.green.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Income',
                    style: TextStyle(
                      color: _selectedType == 'income' ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter an amount';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Account/Wallet Selector
            DropdownButtonFormField<int>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Account / Wallet',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              items: provider.accounts.map((acc) {
                return DropdownMenuItem(
                  value: acc.id,
                  child: Text('${acc.name} (${Helpers.formatCurrency(acc.balance)})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
              validator: (val) => val == null ? 'Please select a wallet' : null,
            ),
            const SizedBox(height: 20),
            
            CategorySelectorField(
              categories: provider.categories,
              initialValue: _selectedCategoryId,
              onCategoryChanged: (value) => setState(() => _selectedCategoryId = value),
              validator: (value) => value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant (Optional)',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(Helpers.formatDate(_selectedDate.toString())),
              tileColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 20),

            // Receipt Upload
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Receipt Attachment'),
              subtitle: Text(_receiptPath == null ? 'No receipt uploaded' : 'receipt_copy.pdf'),
              trailing: _receiptPath == null 
                  ? const Icon(Icons.upload_file)
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () => setState(() => _receiptPath = null),
                    ),
              tileColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () {
                setState(() => _receiptPath = '/receipts/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulated receipt attachment successful!')),
                );
              },
            ),
            const SizedBox(height: 28),
            
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final transaction = Transaction(
                    amount: double.parse(_amountController.text),
                    categoryId: _selectedCategoryId!,
                    accountId: _selectedAccountId!,
                    note: _noteController.text,
                    date: DateFormat('yyyy-MM-dd').format(_selectedDate),
                    type: _selectedType,
                    merchant: _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim(),
                    location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
                    receiptPath: _receiptPath,
                  );
                  
                  await provider.addExpense(transaction);
                  await SoundService.playSuccess();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}