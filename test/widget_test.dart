import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/database/database_helper.dart';

void main() {
  setUp(() {
    // Enable SQLite mock in tests
    DatabaseHelper.isTesting = true;
    DatabaseHelper.testSettings = {'monthly_budget': '1000.0', 'base_currency': 'USD'};
    DatabaseHelper.testAccounts = [
      {'id': 1, 'name': 'Cash', 'type': 'Cash', 'balance': 1000.0, 'currency': 'USD'},
      {'id': 2, 'name': 'Bank Account', 'type': 'Bank Account', 'balance': 5000.0, 'currency': 'USD'},
    ];
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    DatabaseHelper.testExpenses = [
      {
        'id': 1,
        'amount': 250.0,
        'category_id': 1,
        'account_id': 1,
        'note': 'Weekly groceries',
        'date': '$currentMonth-10',
        'type': 'expense',
        'category_name': 'Food & Groceries',
        'category_icon': '🍔',
        'category_color': 'FF6B6B',
        'account_name': 'Cash',
      },
      {
        'id': 2,
        'amount': 1500.0,
        'category_id': 5,
        'account_id': 2,
        'note': 'Paycheck',
        'date': '$currentMonth-01',
        'type': 'income',
        'category_name': 'Salary',
        'category_icon': '💰',
        'category_color': '4CAF50',
        'account_name': 'Bank Account',
      },
    ];
    DatabaseHelper.testBudgets = [];
    DatabaseHelper.testSavingsGoals = [];
    DatabaseHelper.testDebts = [];
    DatabaseHelper.testBills = [];
  });

  testWidgets('Expense tracker cash flow smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('WealthJoy'), findsOneWidget);

    // Net Worth = Cash ($1000) + Bank ($5000) = $6000.00
    expect(find.text('\$6000.00'), findsOneWidget);

    // Monthly Income = +$1500.00 shown in balance card summary
    expect(find.text('+\$1500.00'), findsWidgets);
    // Monthly Expenses = -$250.00 shown in balance card summary
    expect(find.text('-\$250.00'), findsWidgets);

    // Budget details: Budget = $1000.00 (also shown in Cash wallet chip), Remaining = $750.00
    expect(find.text('\$1000.00'), findsWidgets); // Budget + Cash wallet balance
    expect(find.text('\$750.00'), findsOneWidget);

    // Transaction list items
    expect(find.text('Weekly groceries'), findsOneWidget);
    expect(find.text('Paycheck'), findsOneWidget);

    // Navigate to Statistics
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    // Stats screen has Income/Expenses summary and tabbed views
    expect(find.text('Income'), findsWidgets);
    expect(find.text('Expenses'), findsWidgets);
    // Verify category tab content
    expect(find.text('Categories'), findsWidgets);

    // Navigate back to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('WealthJoy'), findsOneWidget);
  });
}
