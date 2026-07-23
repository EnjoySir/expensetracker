import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static bool isTesting = false;
  static List<Map<String, dynamic>> testExpenses = []; // Holds transactions
  static List<Map<String, dynamic>> testCategories = [
    {'id': 1, 'name': 'Food & Groceries', 'icon': '🍔', 'color': 'FF6B6B', 'is_default': 1},
    {'id': 2, 'name': 'Transport', 'icon': '🚗', 'color': '4ECDC4', 'is_default': 1},
    {'id': 3, 'name': 'Rent', 'icon': '🏠', 'color': 'FFE66D', 'is_default': 1},
    {'id': 4, 'name': 'Utilities', 'icon': '💡', 'color': 'FF8B94', 'is_default': 1},
    {'id': 5, 'name': 'Salary', 'icon': '💰', 'color': '4CAF50', 'is_default': 1},
    {'id': 6, 'name': 'Other', 'icon': '📌', 'color': '9E9E9E', 'is_default': 1},
  ];
  static List<Map<String, dynamic>> testAccounts = [
    {'id': 1, 'name': 'Cash', 'type': 'Cash', 'balance': 1000.0, 'currency': 'USD'},
    {'id': 2, 'name': 'Bank Account', 'type': 'Bank Account', 'balance': 5000.0, 'currency': 'USD'},
  ];
  static List<Map<String, dynamic>> testBudgets = [];
  static List<Map<String, dynamic>> testSavingsGoals = [];
  static List<Map<String, dynamic>> testDebts = [];
  static List<Map<String, dynamic>> testBills = [];
  static Map<String, String> testSettings = {'monthly_budget': '1000.0', 'base_currency': 'USD'};

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_tracker.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_default INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'USD'
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        merchant TEXT,
        receipt_path TEXT,
        location TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL UNIQUE,
        amount_limit REAL NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0.0,
        deadline TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        due_date TEXT NOT NULL,
        remaining_balance REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _insertDefaultCategories(db);
    await db.insert('settings', {'key': 'monthly_budget', 'value': '0.0'});
    await db.insert('settings', {'key': 'base_currency', 'value': 'USD'});

    await db.insert('accounts', {'name': 'Cash', 'type': 'Cash', 'balance': 0.0, 'currency': 'USD'});
    await db.insert('accounts', {'name': 'Bank Account', 'type': 'Bank Account', 'balance': 0.0, 'currency': 'USD'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      await db.insert('settings', {'key': 'monthly_budget', 'value': '0.0'});
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE expenses ADD COLUMN type TEXT NOT NULL DEFAULT "expense"');
      } catch (e) {}
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0.0,
          currency TEXT NOT NULL DEFAULT 'USD'
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_id INTEGER NOT NULL UNIQUE,
          amount_limit REAL NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          saved_amount REAL NOT NULL DEFAULT 0.0,
          deadline TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS debts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          person TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          due_date TEXT NOT NULL,
          remaining_balance REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'active'
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS bills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          due_date TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          is_paid INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          category_id INTEGER NOT NULL,
          account_id INTEGER NOT NULL,
          note TEXT,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          merchant TEXT,
          receipt_path TEXT,
          location TEXT,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
          FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
        )
      ''');

      await db.insert('settings', {'key': 'base_currency', 'value': 'USD'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('accounts', {'id': 1, 'name': 'Cash', 'type': 'Cash', 'balance': 0.0, 'currency': 'USD'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('accounts', {'id': 2, 'name': 'Bank Account', 'type': 'Bank Account', 'balance': 0.0, 'currency': 'USD'}, conflictAlgorithm: ConflictAlgorithm.ignore);

      try {
        await db.execute('''
          INSERT INTO transactions (id, amount, category_id, account_id, note, date, type)
          SELECT id, amount, category_id, 1, note, date, type FROM expenses
        ''');
        await db.execute('DROP TABLE IF EXISTS expenses');
      } catch (e) {
        print('Error migrating data: $e');
      }
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Food & Groceries', 'icon': '🍔', 'color': 'FF6B6B', 'is_default': 1},
      {'name': 'Transport', 'icon': '🚗', 'color': '4ECDC4', 'is_default': 1},
      {'name': 'Rent', 'icon': '🏠', 'color': 'FFE66D', 'is_default': 1},
      {'name': 'Utilities', 'icon': '💡', 'color': 'FF8B94', 'is_default': 1},
      {'name': 'Internet', 'icon': '📶', 'color': 'A8E6CF', 'is_default': 1},
      {'name': 'Electricity', 'icon': '⚡', 'color': 'FFE66D', 'is_default': 1},
      {'name': 'Water', 'icon': '💧', 'color': 'C7CEEA', 'is_default': 1},
      {'name': 'Fuel', 'icon': '⛽', 'color': 'FF9800', 'is_default': 1},
      {'name': 'Shopping', 'icon': '🛍️', 'color': 'FFE66D', 'is_default': 1},
      {'name': 'Entertainment', 'icon': '🎬', 'color': 'A8E6CF', 'is_default': 1},
      {'name': 'Health', 'icon': '💊', 'color': 'C7CEEA', 'is_default': 1},
      {'name': 'Education', 'icon': '📚', 'color': 'B5EAD7', 'is_default': 1},
      {'name': 'Insurance', 'icon': '🛡️', 'color': '9C27B0', 'is_default': 1},
      {'name': 'Loan Payments', 'icon': '💸', 'color': 'FF6B6B', 'is_default': 1},
      {'name': 'Clothing', 'icon': '👕', 'color': '4ECDC4', 'is_default': 1},
      {'name': 'Gifts', 'icon': '🎁', 'color': 'FF8B94', 'is_default': 1},
      {'name': 'Travel', 'icon': '✈️', 'color': 'C7CEEA', 'is_default': 1},
      {'name': 'Pets', 'icon': '🐶', 'color': 'B5EAD7', 'is_default': 1},
      {'name': 'Taxes', 'icon': '🏦', 'color': '9E9E9E', 'is_default': 1},
      {'name': 'Charity', 'icon': '🤝', 'color': '4CAF50', 'is_default': 1},
      {'name': 'Miscellaneous', 'icon': '📌', 'color': '9E9E9E', 'is_default': 1},
      {'name': 'Salary', 'icon': '💰', 'color': '4CAF50', 'is_default': 1},
      {'name': 'Business', 'icon': '🏢', 'color': '4CAF50', 'is_default': 1},
      {'name': 'Freelancing', 'icon': '💻', 'color': '4CAF50', 'is_default': 1},
      {'name': 'Investments', 'icon': '📈', 'color': '4CAF50', 'is_default': 1},
      {'name': 'Interest', 'icon': '📊', 'color': '4CAF50', 'is_default': 1},
      {'name': 'Other', 'icon': '📌', 'color': '9E9E9E', 'is_default': 1},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // --- Accounts (Wallets) CRUD ---
  Future<List<Map<String, dynamic>>> getAccounts() async {
    if (isTesting) return testAccounts;
    Database db = await database;
    return await db.query('accounts', orderBy: 'name ASC');
  }

  Future<int> insertAccount(Map<String, dynamic> account) async {
    if (isTesting) {
      final newAcc = Map<String, dynamic>.from(account);
      newAcc['id'] = testAccounts.length + 1;
      testAccounts.add(newAcc);
      return newAcc['id'];
    }
    Database db = await database;
    return await db.insert('accounts', account);
  }

  Future<int> updateAccount(Map<String, dynamic> account) async {
    if (isTesting) {
      final idx = testAccounts.indexWhere((a) => a['id'] == account['id']);
      if (idx != -1) {
        testAccounts[idx] = Map<String, dynamic>.from(testAccounts[idx])..addAll(account);
      }
      return 1;
    }
    Database db = await database;
    return await db.update('accounts', account, where: 'id = ?', whereArgs: [account['id']]);
  }

  Future<int> deleteAccount(int id) async {
    if (isTesting) {
      testAccounts.removeWhere((a) => a['id'] == id);
      return 1;
    }
    Database db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAccountBalance(int accountId, double changeAmount) async {
    if (isTesting) {
      final idx = testAccounts.indexWhere((a) => a['id'] == accountId);
      if (idx != -1) {
        final current = testAccounts[idx];
        final balance = ((current['balance'] as num).toDouble()) + changeAmount;
        testAccounts[idx] = Map<String, dynamic>.from(current)..['balance'] = balance;
      }
      return;
    }
    Database db = await database;
    await db.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [changeAmount, accountId]);
  }

  // --- Categories CRUD ---
  Future<List<Map<String, dynamic>>> getCategories() async {
    if (isTesting) return testCategories;
    Database db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    if (isTesting) {
      final newCat = Map<String, dynamic>.from(category);
      newCat['id'] = testCategories.length + 1;
      testCategories.add(newCat);
      return newCat['id'];
    }
    Database db = await database;
    return await db.insert('categories', category);
  }

  Future<int> deleteCategory(int id) async {
    if (isTesting) {
      testCategories.removeWhere((c) => c['id'] == id);
      return 1;
    }
    Database db = await database;
    return await db.delete('categories', where: 'id = ? AND is_default = 0', whereArgs: [id]);
  }

  // --- Transactions CRUD (replacing legacy getExpenses) ---
  Future<List<Map<String, dynamic>>> getExpenses() async {
    if (isTesting) return testExpenses;
    Database db = await database;
    return await db.rawQuery('''
      SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color, a.name as account_name
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      JOIN accounts a ON t.account_id = a.id
      ORDER BY t.date DESC
    ''');
  }

  Future<int> insertExpense(Map<String, dynamic> transaction) async {
    final double amount = (transaction['amount'] as num).toDouble();
    final String type = transaction['type'] ?? 'expense';
    final int accountId = transaction['account_id'] ?? 1;
    final double balanceChange = type == 'income' ? amount : -amount;
    
    await updateAccountBalance(accountId, balanceChange);

    if (isTesting) {
      final newTx = Map<String, dynamic>.from(transaction);
      newTx['id'] = testExpenses.length + 1;
      final cat = testCategories.firstWhere((c) => c['id'] == transaction['category_id'], orElse: () => testCategories.first);
      final acc = testAccounts.firstWhere((a) => a['id'] == accountId, orElse: () => testAccounts.first);
      newTx['category_name'] = cat['name'];
      newTx['category_icon'] = cat['icon'];
      newTx['category_color'] = cat['color'];
      newTx['account_name'] = acc['name'];
      testExpenses.add(newTx);
      testExpenses.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return newTx['id'];
    }
    
    Database db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<int> updateExpense(Map<String, dynamic> transaction) async {
    final int id = transaction['id'];
    double oldAmount = 0.0;
    String oldType = 'expense';
    int oldAccountId = 1;

    if (isTesting) {
      final idx = testExpenses.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        oldAmount = (testExpenses[idx]['amount'] as num).toDouble();
        oldType = testExpenses[idx]['type'] ?? 'expense';
        oldAccountId = testExpenses[idx]['account_id'] ?? 1;
      }
    } else {
      Database db = await database;
      var result = await db.query('transactions', columns: ['amount', 'type', 'account_id'], where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        oldAmount = (result.first['amount'] as num).toDouble();
        oldType = result.first['type'] as String? ?? 'expense';
        oldAccountId = result.first['account_id'] as int? ?? 1;
      }
    }

    // Reverse old balance change
    final double reverseChange = oldType == 'income' ? -oldAmount : oldAmount;
    await updateAccountBalance(oldAccountId, reverseChange);

    // Apply new balance change
    final double newAmount = (transaction['amount'] as num).toDouble();
    final String newType = transaction['type'] ?? 'expense';
    final int newAccountId = transaction['account_id'] ?? 1;
    final double newChange = newType == 'income' ? newAmount : -newAmount;
    await updateAccountBalance(newAccountId, newChange);

    if (isTesting) {
      final idx = testExpenses.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        final current = testExpenses[idx];
        final updated = Map<String, dynamic>.from(current)..addAll(transaction);
        final cat = testCategories.firstWhere((c) => c['id'] == updated['category_id'], orElse: () => testCategories.first);
        final acc = testAccounts.firstWhere((a) => a['id'] == newAccountId, orElse: () => testAccounts.first);
        updated['category_name'] = cat['name'];
        updated['category_icon'] = cat['icon'];
        updated['category_color'] = cat['color'];
        updated['account_name'] = acc['name'];
        testExpenses[idx] = updated;
      }
      return 1;
    }

    Database db = await database;
    return await db.update('transactions', transaction, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpense(int id) async {
    double oldAmount = 0.0;
    String oldType = 'expense';
    int oldAccountId = 1;

    if (isTesting) {
      final idx = testExpenses.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        oldAmount = (testExpenses[idx]['amount'] as num).toDouble();
        oldType = testExpenses[idx]['type'] ?? 'expense';
        oldAccountId = testExpenses[idx]['account_id'] ?? 1;
      }
    } else {
      Database db = await database;
      var result = await db.query('transactions', columns: ['amount', 'type', 'account_id'], where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        oldAmount = (result.first['amount'] as num).toDouble();
        oldType = result.first['type'] as String? ?? 'expense';
        oldAccountId = result.first['account_id'] as int? ?? 1;
      }
    }

    // Reverse old balance change
    final double reverseChange = oldType == 'income' ? -oldAmount : oldAmount;
    await updateAccountBalance(oldAccountId, reverseChange);

    if (isTesting) {
      testExpenses.removeWhere((e) => e['id'] == id);
      return 1;
    }

    Database db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getMonthlyTotal(String yearMonth) async {
    if (isTesting) {
      return testExpenses
          .where((e) => (e['date'] as String).startsWith(yearMonth) && (e['type'] ?? 'expense') == 'expense')
          .fold<double>(0.0, (sum, e) => sum + (e['amount'] as double));
    }
    Database db = await database;
    var result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE substr(date, 1, 7) = ? AND type = 'expense'
    ''', [yearMonth]);
    return result.first['total'] as double? ?? 0.0;
  }
  
  Future<Map<String, double>> getCategoryBreakdown(String yearMonth) async {
    if (isTesting) {
      Map<String, double> breakdown = {};
      final list = testExpenses.where((e) => (e['date'] as String).startsWith(yearMonth) && (e['type'] ?? 'expense') == 'expense');
      for (var e in list) {
        final name = e['category_name'] as String? ?? 'Other';
        breakdown[name] = (breakdown[name] ?? 0.0) + (e['amount'] as double);
      }
      return breakdown;
    }
    Database db = await database;
    var result = await db.rawQuery('''
      SELECT c.name, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE substr(t.date, 1, 7) = ? AND t.type = 'expense'
      GROUP BY c.name
    ''', [yearMonth]);
    
    Map<String, double> breakdown = {};
    for (var row in result) {
      breakdown[row['name'] as String] = (row['total'] as num).toDouble();
    }
    return breakdown;
  }

  // --- Budgets CRUD ---
  Future<List<Map<String, dynamic>>> getBudgets() async {
    if (isTesting) return testBudgets;
    Database db = await database;
    return await db.rawQuery('''
      SELECT b.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM budgets b
      JOIN categories c ON b.category_id = c.id
    ''');
  }

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    if (isTesting) {
      final newB = Map<String, dynamic>.from(budget);
      newB['id'] = testBudgets.length + 1;
      final cat = testCategories.firstWhere((c) => c['id'] == budget['category_id'], orElse: () => testCategories.first);
      newB['category_name'] = cat['name'];
      newB['category_icon'] = cat['icon'];
      newB['category_color'] = cat['color'];
      
      // Prevent duplicates in mocks
      testBudgets.removeWhere((b) => b['category_id'] == budget['category_id']);
      testBudgets.add(newB);
      return newB['id'];
    }
    Database db = await database;
    return await db.insert('budgets', budget, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteBudget(int id) async {
    if (isTesting) {
      testBudgets.removeWhere((b) => b['id'] == id);
      return 1;
    }
    Database db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Savings Goals CRUD ---
  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    if (isTesting) return testSavingsGoals;
    Database db = await database;
    return await db.query('savings_goals', orderBy: 'deadline ASC');
  }

  Future<int> insertSavingsGoal(Map<String, dynamic> goal) async {
    if (isTesting) {
      final newG = Map<String, dynamic>.from(goal);
      newG['id'] = testSavingsGoals.length + 1;
      testSavingsGoals.add(newG);
      return newG['id'];
    }
    Database db = await database;
    return await db.insert('savings_goals', goal);
  }

  Future<int> updateSavingsGoal(Map<String, dynamic> goal) async {
    if (isTesting) {
      final idx = testSavingsGoals.indexWhere((g) => g['id'] == goal['id']);
      if (idx != -1) {
        testSavingsGoals[idx] = Map<String, dynamic>.from(testSavingsGoals[idx])..addAll(goal);
      }
      return 1;
    }
    Database db = await database;
    return await db.update('savings_goals', goal, where: 'id = ?', whereArgs: [goal['id']]);
  }

  Future<int> deleteSavingsGoal(int id) async {
    if (isTesting) {
      testSavingsGoals.removeWhere((g) => g['id'] == id);
      return 1;
    }
    Database db = await database;
    return await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  // --- Debts & Loans CRUD ---
  Future<List<Map<String, dynamic>>> getDebts() async {
    if (isTesting) return testDebts;
    Database db = await database;
    return await db.query('debts', orderBy: 'due_date ASC');
  }

  Future<int> insertDebt(Map<String, dynamic> debt) async {
    if (isTesting) {
      final newD = Map<String, dynamic>.from(debt);
      newD['id'] = testDebts.length + 1;
      testDebts.add(newD);
      return newD['id'];
    }
    Database db = await database;
    return await db.insert('debts', debt);
  }

  Future<int> updateDebt(Map<String, dynamic> debt) async {
    if (isTesting) {
      final idx = testDebts.indexWhere((d) => d['id'] == debt['id']);
      if (idx != -1) {
        testDebts[idx] = Map<String, dynamic>.from(testDebts[idx])..addAll(debt);
      }
      return 1;
    }
    Database db = await database;
    return await db.update('debts', debt, where: 'id = ?', whereArgs: [debt['id']]);
  }

  Future<int> deleteDebt(int id) async {
    if (isTesting) {
      testDebts.removeWhere((d) => d['id'] == id);
      return 1;
    }
    Database db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Bills & Reminders CRUD ---
  Future<List<Map<String, dynamic>>> getBills() async {
    if (isTesting) return testBills;
    Database db = await database;
    return await db.rawQuery('''
      SELECT b.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM bills b
      JOIN categories c ON b.category_id = c.id
      ORDER BY b.due_date ASC
    ''');
  }

  Future<int> insertBill(Map<String, dynamic> bill) async {
    if (isTesting) {
      final newB = Map<String, dynamic>.from(bill);
      newB['id'] = testBills.length + 1;
      final cat = testCategories.firstWhere((c) => c['id'] == bill['category_id'], orElse: () => testCategories.first);
      newB['category_name'] = cat['name'];
      newB['category_icon'] = cat['icon'];
      newB['category_color'] = cat['color'];
      testBills.add(newB);
      return newB['id'];
    }
    Database db = await database;
    return await db.insert('bills', bill);
  }

  Future<int> updateBill(Map<String, dynamic> bill) async {
    if (isTesting) {
      final idx = testBills.indexWhere((b) => b['id'] == bill['id']);
      if (idx != -1) {
        testBills[idx] = Map<String, dynamic>.from(testBills[idx])..addAll(bill);
      }
      return 1;
    }
    Database db = await database;
    return await db.update('bills', bill, where: 'id = ?', whereArgs: [bill['id']]);
  }

  Future<int> deleteBill(int id) async {
    if (isTesting) {
      testBills.removeWhere((b) => b['id'] == id);
      return 1;
    }
    Database db = await database;
    return await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    if (isTesting) return testSettings[key];
    Database db = await database;
    var result = await db.query('settings', columns: ['value'], where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) return result.first['value'] as String?;
    return null;
  }

  Future<int> setSetting(String key, String value) async {
    if (isTesting) {
      testSettings[key] = value;
      return 1;
    }
    Database db = await database;
    return await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}