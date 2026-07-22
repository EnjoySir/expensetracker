import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/debt.dart';
import '../models/bill.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/helpers.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  List<Debt> _debts = [];
  List<Bill> _bills = [];
  
  bool _isLoading = false;
  double _monthlyBudget = 1000.0;
  String _selectedMonth = Helpers.getCurrentMonth();
  String _baseCurrency = 'USD';
  
  List<Transaction> get transactions => _transactions;
  List<Transaction> get expenses => _transactions; // Compatibility alias
  List<Category> get categories => _categories;
  List<Account> get accounts => _accounts;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<Debt> get debts => _debts;
  List<Bill> get bills => _bills;
  
  bool get isLoading => _isLoading;
  double get monthlyBudget => _monthlyBudget;
  String get selectedMonth => _selectedMonth;
  String get baseCurrency => _baseCurrency;
  
  double get netWorth {
    return _accounts.fold(0.0, (sum, item) => sum + item.balance);
  }

  List<Transaction> get filteredExpenses {
    return _transactions.where((e) => e.date.startsWith(_selectedMonth)).toList();
  }

  double get totalExpenses {
    return _transactions
        .where((e) => e.type == 'expense' && e.date.startsWith(_selectedMonth))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalIncome {
    return _transactions
        .where((e) => e.type == 'income' && e.date.startsWith(_selectedMonth))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Future<void> updateBudget(double budget) async {
    _monthlyBudget = budget;
    await DatabaseHelper().setSetting('monthly_budget', budget.toString());
    notifyListeners();
  }

  Future<void> updateBaseCurrency(String currency) async {
    _baseCurrency = currency;
    await DatabaseHelper().setSetting('base_currency', currency);
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    await loadAllData();
  }

  Future<void> loadCategories() async {
    await loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      final txData = await DatabaseHelper().getExpenses();
      _transactions = txData.map((e) => Transaction.fromMap(e)).toList();

      final catData = await DatabaseHelper().getCategories();
      _categories = catData.map((c) => Category.fromMap(c)).toList();

      final accData = await DatabaseHelper().getAccounts();
      _accounts = accData.map((a) => Account.fromMap(a)).toList();

      final budData = await DatabaseHelper().getBudgets();
      _budgets = budData.map((b) => Budget.fromMap(b)).toList();

      final goalData = await DatabaseHelper().getSavingsGoals();
      _savingsGoals = goalData.map((g) => SavingsGoal.fromMap(g)).toList();

      final debtData = await DatabaseHelper().getDebts();
      _debts = debtData.map((d) => Debt.fromMap(d)).toList();

      final billData = await DatabaseHelper().getBills();
      _bills = billData.map((b) => Bill.fromMap(b)).toList();

      final currency = await DatabaseHelper().getSetting('base_currency');
      if (currency != null) _baseCurrency = currency;

      final budgetStr = await DatabaseHelper().getSetting('monthly_budget');
      if (budgetStr != null) {
        _monthlyBudget = double.tryParse(budgetStr) ?? 1000.0;
      }
    } catch (e) {
      print('Error loading all data in provider: $e');
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // --- Transactions CRUD ---
  Future<void> addExpense(Transaction transaction) async {
    await DatabaseHelper().insertExpense(transaction.toMap());
    await loadAllData();
  }

  Future<void> updateExpense(Transaction transaction) async {
    await DatabaseHelper().updateExpense(transaction.toMap());
    await loadAllData();
  }

  Future<void> deleteExpense(int id) async {
    await DatabaseHelper().deleteExpense(id);
    await loadAllData();
  }

  // --- Accounts CRUD ---
  Future<void> addAccount(Account account) async {
    await DatabaseHelper().insertAccount(account.toMap());
    await loadAllData();
  }

  Future<void> updateAccount(Account account) async {
    await DatabaseHelper().updateAccount(account.toMap());
    await loadAllData();
  }

  Future<void> deleteAccount(int id) async {
    await DatabaseHelper().deleteAccount(id);
    await loadAllData();
  }

  Future<void> transferFunds(Account from, Account to, double amount) async {
    await DatabaseHelper().updateAccountBalance(from.id!, -amount);
    await DatabaseHelper().updateAccountBalance(to.id!, amount);

    final outTx = Transaction(
      amount: amount,
      categoryId: 21, // Miscellaneous/Other Category
      accountId: from.id!,
      note: 'Transfer to ${to.name}',
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      type: 'expense',
      merchant: 'Transfer',
    );
    await DatabaseHelper().insertExpense(outTx.toMap());

    final inTx = Transaction(
      amount: amount,
      categoryId: 21,
      accountId: to.id!,
      note: 'Transfer from ${from.name}',
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      type: 'income',
      merchant: 'Transfer',
    );
    await DatabaseHelper().insertExpense(inTx.toMap());

    await loadAllData();
  }

  // --- Budgets CRUD ---
  Future<void> addBudget(Budget budget) async {
    await DatabaseHelper().insertBudget(budget.toMap());
    await loadAllData();
  }

  Future<void> deleteBudget(int id) async {
    await DatabaseHelper().deleteBudget(id);
    await loadAllData();
  }

  // --- Savings Goals CRUD ---
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await DatabaseHelper().insertSavingsGoal(goal.toMap());
    await loadAllData();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await DatabaseHelper().updateSavingsGoal(goal.toMap());
    await loadAllData();
  }

  Future<void> deleteSavingsGoal(int id) async {
    await DatabaseHelper().deleteSavingsGoal(id);
    await loadAllData();
  }

  // --- Debts CRUD ---
  Future<void> addDebt(Debt debt) async {
    await DatabaseHelper().insertDebt(debt.toMap());
    await loadAllData();
  }

  Future<void> updateDebt(Debt debt) async {
    await DatabaseHelper().updateDebt(debt.toMap());
    await loadAllData();
  }

  Future<void> deleteDebt(int id) async {
    await DatabaseHelper().deleteDebt(id);
    await loadAllData();
  }

  // --- Bills CRUD ---
  Future<void> addBill(Bill bill) async {
    await DatabaseHelper().insertBill(bill.toMap());
    await loadAllData();
  }

  Future<void> updateBill(Bill bill) async {
    await DatabaseHelper().updateBill(bill.toMap());
    await loadAllData();
  }

  Future<void> deleteBill(int id) async {
    await DatabaseHelper().deleteBill(id);
    await loadAllData();
  }

  Future<void> addCategory(Category category) async {
    await DatabaseHelper().insertCategory(category.toMap());
    await loadAllData();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper().deleteCategory(id);
    await loadAllData();
  }

  // --- Legacy helpers ---
  double getMonthlyTotal(String yearMonth) {
    return _transactions
        .where((e) => e.date.startsWith(yearMonth) && e.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getMonthlyIncomeTotal(String yearMonth) {
    return _transactions
        .where((e) => e.date.startsWith(yearMonth) && e.type == 'income')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getCategoryMonthlyTotal(int categoryId, String yearMonth) {
    return _transactions
        .where((e) => e.categoryId == categoryId && e.date.startsWith(yearMonth) && e.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> getMonthlyCategoryBreakdown(String yearMonth) {
    Map<String, double> breakdown = {};
    final monthExpenses = _transactions.where((e) => e.date.startsWith(yearMonth) && e.type == 'expense');
    
    for (var expense in monthExpenses) {
      String categoryName = expense.categoryName ?? 'Other';
      breakdown[categoryName] = (breakdown[categoryName] ?? 0.0) + expense.amount;
    }
    return breakdown;
  }

  List<Transaction> getRecentExpenses({int limit = 10}) {
    return _transactions.take(limit).toList();
  }
}