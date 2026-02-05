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

  // ✅ Show details when a chart slice is tapped
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

  @override
  Widget build(BuildContext context) {
    final summary = StorageService.getDashboardSummary(fortnightOffset);
    final range = StorageService.getFortnightRange(fortnightOffset);
    final chartData = StorageService.getCategoryTotals(fortnightOffset);

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
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
                          "Income", summary['income']!, Colors.teal)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildSmallCard(
                          "Expenses", summary['expenses']!, Colors.blueGrey)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildSmallCard(
                          "Savings", summary['savings']!, Colors.indigo)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildSmallCard("Remaining", summary['remaining']!,
                          Colors.deepPurple)),
                ],
              ),

              const SizedBox(height: 12),

              /// --- Doughnut Chart ---
              SizedBox(
                height: 460,
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
                        child: SfCircularChart(
                          legend: const Legend(
                            isVisible: true,
                            position: LegendPosition.bottom,
                            overflowMode: LegendItemOverflowMode.wrap,
                          ),
                          palette: const <Color>[
                            Colors.teal,
                            Colors.indigo,
                            Colors.deepPurple,
                            Colors.blueGrey,
                            Colors.orange,
                            Colors.redAccent
                          ],
                          series: <CircularSeries>[
                            DoughnutSeries<ChartData, String>(
                              dataSource: chartData,
                              xValueMapper: (ChartData data, _) =>
                                  data.category,
                              yValueMapper: (ChartData data, _) => data.amount,
                              innerRadius: '70%',
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                labelPosition: ChartDataLabelPosition.outside,
                                textStyle: TextStyle(fontSize: 10),
                              ),
                              enableTooltip: true,
                              // ✅ Detect tap on segments - FIXED CLASS NAME
                              onPointTap: (ChartPointDetails args) {
                                if (args.pointIndex != null) {
                                  final category =
                                      chartData[args.pointIndex!].category;
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

  // --- Small Summary Card ---
  Widget _buildSmallCard(String label, double value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text("\$${value.toStringAsFixed(2)}",
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }

  // --- Navigation Button ---
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
