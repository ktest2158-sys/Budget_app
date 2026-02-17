import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'expense_list_screen.dart';
import 'income_list_screen.dart';
import 'settings_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int fortnightOffset = 0;

  void _showCategoryDetails(String category) {
    final categoryExpenses =
        StorageService.getExpensesByCategory(fortnightOffset, category);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$category Details",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              if (categoryExpenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No expenses recorded for this category."),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categoryExpenses.length,
                    itemBuilder: (context, index) {
                      final exp = categoryExpenses[index];
                      return ListTile(
                        leading: const Icon(Icons.arrow_right),
                        title: Text(exp.name),
                        trailing: Text("\$${exp.amount.toStringAsFixed(2)}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(exp.date != null
                            ? "${exp.date!.day}/${exp.date!.month}/${exp.date!.year}"
                            : ""),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ✅ NEW: Savings breakdown modal — fortnight headers with named lines
  void _showSavingsBreakdown() {
    final breakdown = StorageService.getSavingsBreakdown();
    final total = StorageService.getCumulativeSavings();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Saved',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: total >= 0 ? Colors.indigo : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (breakdown.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No savings recorded yet.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: breakdown.length,
                        itemBuilder: (context, index) {
                          final group = breakdown[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fortnight header
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          group.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${group.subtotal >= 0 ? '+' : ''}\$${group.subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: group.subtotal >= 0
                                            ? Colors.indigo
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Individual savings lines
                              ...group.items.map((exp) {
                                final isWithdrawal = exp.isSavingsWithdrawal;
                                // Format: "Holiday Fund · flights  -$350" or "Holiday Fund  +$200"
                                final displayName = isWithdrawal
                                    ? '${exp.savingsBucket} · ${exp.name}'
                                    : exp.name;
                                final amountStr = isWithdrawal
                                    ? '-\$${exp.amount.toStringAsFixed(2)}'
                                    : '+\$${exp.amount.toStringAsFixed(2)}';
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, bottom: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              isWithdrawal
                                                  ? Icons.arrow_upward
                                                  : Icons.savings,
                                              size: 14,
                                              color: isWithdrawal
                                                  ? Colors.red
                                                  : Colors.indigo,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                displayName,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        amountStr,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isWithdrawal
                                              ? Colors.red
                                              : Colors.indigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ NEW: Remaining breakdown modal — one row per fortnight
  void _showRemainingBreakdown() {
    final breakdown = StorageService.getRemainingBreakdown();
    final total = StorageService.getCumulativeRemaining();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Remaining',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: total >= 0 ? Colors.deepPurple : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (breakdown.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No data yet.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: breakdown.length,
                        itemBuilder: (context, index) {
                          final row = breakdown[index];
                          final isNegative = row.amount < 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(row.label,
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                Text(
                                  '\$${row.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isNegative
                                        ? Colors.red
                                        : Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = StorageService.getDashboardSummary(fortnightOffset);
    final range = StorageService.getFortnightRange(fortnightOffset);
    final chartData = StorageService.getCategoryTotals(fortnightOffset);
    final showChart = StorageService.getShowChart(); // ✅ Chart toggle

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Budget Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {}); // Refresh chart toggle on return
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // --- Fortnight Navigation ---
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha((0.05 * 255).round()),
                        blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => setState(() => fortnightOffset--),
                    ),
                    Column(
                      children: [
                        Text("Fortnight Period",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        Text(
                          "${range['start']!.day}/${range['start']!.month} - ${range['end']!.day}/${range['end']!.month}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 20),
                      onPressed: () => setState(() => fortnightOffset++),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // --- Summary Grid ---
              Row(
                children: [
                  Expanded(
                      child: _buildSmallCard(
                    label: "Income",
                    value: summary['income']!,
                    accentColor: Colors.teal,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildSmallCard(
                    label: "Expenses",
                    value: summary['expenses']!,
                    accentColor: Colors.blueGrey,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // ✅ Savings card — tappable, shows cumulative + breakdown
                  Expanded(
                      child: _buildSmallCard(
                    label: "Savings",
                    value: summary['savings']!,
                    accentColor: Colors.indigo,
                    onTap: _showSavingsBreakdown,
                    subtitle: 'Cumulative · tap for details',
                  )),
                  const SizedBox(width: 8),
                  // ✅ Remaining card — tappable, shows cumulative + breakdown
                  Expanded(
                      child: _buildSmallCard(
                    label: "Remaining",
                    value: summary['remaining']!,
                    accentColor: Colors.deepPurple,
                    onTap: _showRemainingBreakdown,
                    subtitle: 'Cumulative · tap for details',
                  )),
                ],
              ),

              const SizedBox(height: 12),

              // ✅ Doughnut chart — conditionally rendered
              if (showChart)
                SizedBox(
                  height: 300,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.05 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Expenses by Category",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 7),
                        Expanded(
                          child: chartData.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.pie_chart_outline,
                                          size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No expenses recorded yet",
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                )
                              : SfCircularChart(
                                  legend: const Legend(
                                    isVisible: true,
                                    position: LegendPosition.bottom,
                                    overflowMode: LegendItemOverflowMode.wrap,
                                  ),
                                  palette: StorageService.getChartColors(),
                                  series: <CircularSeries>[
                                    DoughnutSeries<ChartData, String>(
                                      dataSource: chartData,
                                      xValueMapper: (ChartData data, _) =>
                                          data.category,
                                      yValueMapper: (ChartData data, _) =>
                                          data.amount,
                                      radius: '80%',
                                      innerRadius: '70%',
                                      dataLabelSettings:
                                          const DataLabelSettings(
                                        isVisible: true,
                                        labelPosition:
                                            ChartDataLabelPosition.outside,
                                        textStyle: TextStyle(fontSize: 10),
                                      ),
                                      enableTooltip: true,
                                      onPointTap: (ChartPointDetails args) {
                                        if (args.pointIndex != null) {
                                          final category =
                                              chartData[args.pointIndex!]
                                                  .category;
                                          _showCategoryDetails(category);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // --- Navigation Buttons ---
              Row(
                children: [
                  Expanded(
                    child: _buildNavButton(
                      context,
                      label: "Manage Expenses",
                      icon: Icons.receipt_long_outlined,
                      color: Colors.black87,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ExpenseListScreen(
                                  fortnightOffset: fortnightOffset)),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNavButton(
                      context,
                      label: "Manage Income",
                      icon: Icons.account_balance_outlined,
                      color: Colors.black87,
                      isOutlined: true,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => IncomeListScreen(
                                  fortnightOffset: fortnightOffset)),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ UPDATED: Added optional onTap and subtitle for cumulative cards
  Widget _buildSmallCard({
    required String label,
    required double value,
    required Color accentColor,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final isNegative = value < 0;
    final displayColor = isNegative ? Colors.red : accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: accentColor, width: 5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                if (onTap != null)
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "\$${value.toStringAsFixed(2)}",
              style: TextStyle(
                  color: displayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            if (subtitle != null)
              Text(subtitle,
                  style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onPressed,
      required Color color,
      bool isOutlined = false}) {
    if (isOutlined) {
      return SizedBox(
        height: 55,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          label: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
