import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../utils/color_helper.dart';
import '../utils/helpers.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final currentMonth = provider.selectedMonth;
    final monthExpenses = provider.filteredExpenses.where((e) => e.type == 'expense').toList();
    final monthIncome = provider.filteredExpenses.where((e) => e.type == 'income').toList();
    final totalSpent = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalEarned = monthIncome.fold(0.0, (sum, e) => sum + e.amount);

    // Category breakdown for pie chart
    Map<String, double> categoryTotals = {};
    Map<String, String> categoryColors = {};
    for (var e in monthExpenses) {
      final name = e.categoryName ?? 'Other';
      categoryTotals[name] = (categoryTotals[name] ?? 0.0) + e.amount;
      categoryColors[name] = e.categoryColor ?? '9E9E9E';
    }

    // Monthly trend data (last 6 months)
    final trendData = _buildMonthlyTrend(provider);

    return Scaffold(
      body: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade600],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Text(
                    Helpers.getMonthName(currentMonth),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryTile('Income', Helpers.formatCurrency(totalEarned), Colors.greenAccent),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _summaryTile('Expenses', Helpers.formatCurrency(totalSpent), Colors.redAccent),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _summaryTile('Txns', '${monthExpenses.length + monthIncome.length}', Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.deepPurple.shade700,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Categories', icon: Icon(Icons.pie_chart, size: 18)),
                Tab(text: 'Trends', icon: Icon(Icons.bar_chart, size: 18)),
                Tab(text: 'Cash Flow', icon: Icon(Icons.show_chart, size: 18)),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Pie Chart + Category List
                _buildCategoryTab(categoryTotals, categoryColors, totalSpent),

                // Tab 2: Bar Chart (Monthly Trends)
                _buildTrendTab(trendData),

                // Tab 3: Line Chart (Income vs Expenses)
                _buildCashFlowTab(trendData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- Tab 1: Category Pie Chart ---
  Widget _buildCategoryTab(Map<String, double> categoryTotals, Map<String, String> categoryColors, double totalSpent) {
    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No expense data for this month', style: TextStyle(color: Colors.grey)));
    }

    final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sorted.map((entry) {
                final color = ColorHelper.fromHex(categoryColors[entry.key] ?? '9E9E9E');
                final pct = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0;
                return PieChartSectionData(
                  value: entry.value,
                  color: color,
                  radius: 50,
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 45,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...sorted.map((entry) {
          final color = ColorHelper.fromHex(categoryColors[entry.key] ?? '9E9E9E');
          final pct = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 10),
                Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                Text(Helpers.formatCurrency(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- Tab 2: Bar Chart (Monthly Spending Trend) ---
  Widget _buildTrendTab(List<_MonthData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Not enough data', style: TextStyle(color: Colors.grey)));
    }

    final maxVal = data.fold<double>(0, (prev, d) {
      final m = d.expense > d.income ? d.expense : d.income;
      return m > prev ? m : prev;
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Spending Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Last ${data.length} months', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(toY: e.value.expense, color: Colors.redAccent, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                      BarChartRodData(toY: e.value.income, color: Colors.green.shade600, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(data[idx].label, style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, _) {
                        return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.redAccent, 'Expenses'),
              const SizedBox(width: 20),
              _legendDot(Colors.green.shade600, 'Income'),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Line Chart (Cash Flow) ---
  Widget _buildCashFlowTab(List<_MonthData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Not enough data', style: TextStyle(color: Colors.grey)));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Income vs Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Cash flow over last ${data.length} months', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.income)).toList(),
                    color: Colors.green.shade600,
                    barWidth: 3,
                    isCurved: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                  ),
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.expense)).toList(),
                    color: Colors.redAccent,
                    barWidth: 3,
                    isCurved: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(data[idx].label, style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, _) {
                        return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green.shade600, 'Income'),
              const SizedBox(width: 20),
              _legendDot(Colors.redAccent, 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<_MonthData> _buildMonthlyTrend(ExpenseProvider provider) {
    List<_MonthData> data = [];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i, 1);
      final ym = DateFormat('yyyy-MM').format(dt);
      final label = DateFormat('MMM').format(dt);
      final expense = provider.getMonthlyTotal(ym);
      final income = provider.getMonthlyIncomeTotal(ym);
      data.add(_MonthData(label: label, expense: expense, income: income));
    }
    return data;
  }
}

class _MonthData {
  final String label;
  final double expense;
  final double income;
  _MonthData({required this.label, required this.expense, required this.income});
}