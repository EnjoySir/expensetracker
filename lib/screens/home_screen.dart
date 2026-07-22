import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../utils/helpers.dart';
import '../widgets/balance_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/health_score_card.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/joy_assistant_modal.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';
import 'statistics_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_accounts_screen.dart';

import 'budgets_screen.dart';
import 'savings_goals_screen.dart';
import 'debts_screen.dart';
import 'bills_screen.dart';
import 'currency_converter_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeContent(),
    const StatisticsScreen(),
    const _MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'More',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'joy_ai',
                  backgroundColor: Colors.deepPurple.shade900,
                  icon: const Icon(Icons.graphic_eq, color: Colors.cyanAccent),
                  label: const Text('Hey Joy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => JoyAssistantModal.show(context),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'add_expense',
                  backgroundColor: Colors.deepPurple,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                    ).then((_) => _loadData());
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }
  
  void _loadData() {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    provider.loadAllData();
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuCard(
            context,
            icon: Icons.account_balance_outlined,
            title: 'Category Budgets',
            subtitle: 'Set spending limits per category',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen())),
          ),
          _menuCard(
            context,
            icon: Icons.savings_outlined,
            title: 'Savings Goals',
            subtitle: 'Track progress toward financial goals',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalsScreen())),
          ),
          _menuCard(
            context,
            icon: Icons.handshake_outlined,
            title: 'Debts & Loans',
            subtitle: 'Track money borrowed and lent',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen())),
          ),
          _menuCard(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Bills & Reminders',
            subtitle: 'Track upcoming bills and due dates',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsScreen())),
          ),
          _menuCard(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallets / Accounts',
            subtitle: 'Manage accounts and transfer funds',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageAccountsScreen())),
          ),
          _menuCard(
            context,
            icon: Icons.category_outlined,
            title: 'Manage Categories',
            subtitle: 'Create and manage custom categories',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen())),
          ),
          _menuCard(
            context,
            icon: Icons.currency_exchange,
            title: 'Currency Converter',
            subtitle: 'Live conversion between USD, ZWG, ZAR, EUR, GBP',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencyConverterScreen())),
          ),
          _menuCard(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Currency, security, and preferences',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade50,
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.loadExpenses();
    await provider.loadCategories();
  }

  void _changeMonth(int offset) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final current = DateTime.parse('${provider.selectedMonth}-01');
    final next = DateTime(current.year, current.month + offset, 1);
    final formatted = DateFormat('yyyy-MM').format(next);
    provider.setSelectedMonth(formatted);
  }

  Future<void> _selectMonthPicker(BuildContext context, ExpenseProvider provider) async {
    final current = DateTime.parse('${provider.selectedMonth}-01');
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM').format(picked);
      provider.setSelectedMonth(formatted);
    }
  }

  void _exportToCSV(BuildContext context, List<Transaction> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Date,Category,Type,Amount,Note');
    for (var item in list) {
      final date = item.date;
      final category = item.categoryName ?? 'Unknown';
      final type = item.type;
      final amount = item.amount.toStringAsFixed(2);
      final note = item.note.replaceAll('"', '""');
      csvBuffer.writeln('"$date","$category","$type",$amount," $note"');
    }

    Clipboard.setData(ClipboardData(text: csvBuffer.toString())).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV copied to clipboard! Ready to paste.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showVoiceSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.mic, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voice Search & Dictation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Listening for keywords... Tap a command to search:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Food & Groceries', 'Salary', 'Rent', 'Transport', 'Netflix', 'Shopping', 'Fuel'].map((keyword) {
                  return ActionChip(
                    avatar: const Icon(Icons.record_voice_over, size: 16, color: Colors.deepPurple),
                    label: Text(keyword),
                    backgroundColor: Colors.deepPurple.shade50,
                    onPressed: () {
                      _searchController.text = keyword;
                      setState(() => _searchQuery = keyword);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    
    // Filter expenses by selected month and search query
    final filteredExpenses = provider.filteredExpenses.where((e) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final catName = (e.categoryName ?? '').toLowerCase();
      final note = e.note.toLowerCase();
      return catName.contains(query) || note.contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                tooltip: 'Export CSV',
                onPressed: () => _exportToCSV(context, filteredExpenses),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'WealthJoy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade700],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Premium Balance / Budget Card
                  const BalanceCard(),
                  const SizedBox(height: 16),
                  
                  // Financial Health & Insights Score Card
                  const HealthScoreCard(),
                  const SizedBox(height: 16),

                  // AI Assistant & No-Spend Days Card
                  const AiInsightsCard(),
                  const SizedBox(height: 16),
                  
                  // Wallets Quick List
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.accounts.length,
                      itemBuilder: (context, index) {
                        final account = provider.accounts[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 10),
                          elevation: 0,
                          color: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ManageAccountsScreen()),
                              ).then((_) => provider.loadAllData());
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                                    child: Icon(
                                      account.type == 'Cash'
                                          ? Icons.money_rounded
                                          : account.type == 'Bank Account'
                                              ? Icons.account_balance_rounded
                                              : Icons.credit_card_rounded,
                                      size: 14,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        account.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        Helpers.formatCurrency(account.balance),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
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
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Month Navigator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        onPressed: () => _changeMonth(-1),
                      ),
                      GestureDetector(
                        onTap: () => _selectMonthPicker(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 18, color: Colors.deepPurple),
                              const SizedBox(width: 8),
                              Text(
                                Helpers.getMonthName(provider.selectedMonth),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 28),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search note or category...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.mic, color: Colors.deepPurple),
                            tooltip: 'Voice Search',
                            onPressed: () => _showVoiceSearchModal(context),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                        ],
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Transactions Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          // Expense list (Or Empty State Placeholder)
          if (filteredExpenses.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'No matches found' : 'No expenses for this month',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try changing your search keywords'
                            : 'Tap the + button to add a new transaction',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = filteredExpenses[index];
                    return ExpenseCard(
                      expense: expense,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditExpenseScreen(expense: expense),
                          ),
                        ).then((_) => _loadData());
                      },
                      onLongPress: () => _deleteExpense(context, expense.id!),
                    );
                  },
                  childCount: filteredExpenses.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
  
  void _deleteExpense(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
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
              Navigator.pop(ctx);
              await Provider.of<ExpenseProvider>(context, listen: false)
                  .deleteExpense(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}