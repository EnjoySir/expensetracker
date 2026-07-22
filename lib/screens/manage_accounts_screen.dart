import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/account.dart';
import '../utils/helpers.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  
  String _selectedType = 'Cash';
  String _selectedCurrency = 'USD';
  
  final List<String> _accountTypes = [
    'Cash', 'Bank Account', 'Savings Account', 'EcoCash', 'Mukuru', 
    'Visa Card', 'Mastercard', 'Credit Card'
  ];

  final List<String> _currencies = ['USD', 'ZWG', 'ZAR', 'EUR', 'GBP'];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts / Wallets'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: 'Transfer Funds',
            onPressed: () => _showTransferDialog(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Section: Add Account Form
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Wallet / Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name (e.g. My EcoCash)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Balance', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Account Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _accountTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _currencies.map((curr) {
                          return DropdownMenuItem(value: curr, child: Text(curr));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCurrency = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _createAccount(provider),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Account', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Section: Accounts List
          Expanded(
            child: provider.accounts.isEmpty
                ? const Center(
                    child: Text('No accounts created yet. Add your first wallet above!'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.accounts.length,
                    itemBuilder: (context, index) {
                      final account = provider.accounts[index];
                      final symbol = Helpers.getCurrencySymbol(account.currency);
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(_getIconForType(account.type), color: Colors.deepPurple),
                          ),
                          title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${account.type} • ${account.currency}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Helpers.formatCurrency(account.balance, symbol: symbol),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.deepPurple, size: 20),
                                tooltip: 'Edit Account',
                                onPressed: () => _showEditAccountDialog(context, provider, account),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Delete Account',
                                onPressed: () => _deleteAccount(context, provider, account),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Cash': return Icons.money_rounded;
      case 'Bank Account': return Icons.account_balance_rounded;
      case 'Savings Account': return Icons.savings_rounded;
      case 'EcoCash': return Icons.phone_android_rounded;
      case 'Mukuru': return Icons.send_rounded;
      case 'Visa Card':
      case 'Mastercard':
      case 'Credit Card': return Icons.credit_card_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  void _createAccount(ExpenseProvider provider) async {
    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
      return;
    }

    final double balance = double.tryParse(balanceText) ?? 0.0;

    final account = Account(
      name: name,
      type: _selectedType,
      balance: balance,
      currency: _selectedCurrency,
    );

    await provider.addAccount(account);
    _nameController.clear();
    _balanceController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account "${account.name}" added successfully'), backgroundColor: Colors.green),
      );
    }
  }

  void _showEditAccountDialog(BuildContext context, ExpenseProvider provider, Account account) {
    final nameEditCtrl = TextEditingController(text: account.name);
    final balanceEditCtrl = TextEditingController(text: account.balance.toString());
    String typeEdit = account.type;
    String currencyEdit = account.currency;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit "${account.name}"'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameEditCtrl,
                  decoration: const InputDecoration(labelText: 'Account Name', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: balanceEditCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Balance', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter balance';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: typeEdit,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: _accountTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => typeEdit = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: currencyEdit,
                  decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                  items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => currencyEdit = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final updated = Account(
                    id: account.id,
                    name: nameEditCtrl.text.trim(),
                    type: typeEdit,
                    balance: double.parse(balanceEditCtrl.text),
                    currency: currencyEdit,
                  );
                  await provider.updateAccount(updated);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Account "${updated.name}" updated'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAccount(BuildContext context, ExpenseProvider provider, Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteAccount(account.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account "${account.name}" deleted'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context, ExpenseProvider provider) {
    if (provider.accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least 2 accounts to make transfers.')),
      );
      return;
    }

    Account fromAccount = provider.accounts.first;
    Account toAccount = provider.accounts[1];
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Transfer Funds'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Account>(
                      value: fromAccount,
                      decoration: const InputDecoration(labelText: 'From Wallet', border: OutlineInputBorder()),
                      items: provider.accounts.map((a) {
                        return DropdownMenuItem(value: a, child: Text('${a.name} (${Helpers.formatCurrency(a.balance, symbol: Helpers.getCurrencySymbol(a.currency))})'));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          fromAccount = val!;
                          if (fromAccount.id == toAccount.id) {
                            toAccount = provider.accounts.firstWhere((a) => a.id != fromAccount.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Account>(
                      value: toAccount,
                      decoration: const InputDecoration(labelText: 'To Wallet', border: OutlineInputBorder()),
                      items: provider.accounts.where((a) => a.id != fromAccount.id).map((a) {
                        return DropdownMenuItem(value: a, child: Text('${a.name} (${Helpers.formatCurrency(a.balance, symbol: Helpers.getCurrencySymbol(a.currency))})'));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          toAccount = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter an amount';
                        final double? amt = double.tryParse(val);
                        if (amt == null || amt <= 0) return 'Enter a positive amount';
                        if (amt > fromAccount.balance) return 'Insufficient funds';
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
                      final amt = double.parse(amountController.text);
                      await provider.transferFunds(fromAccount, toAccount, amt);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Transferred ${Helpers.formatCurrency(amt)} from ${fromAccount.name} to ${toAccount.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
