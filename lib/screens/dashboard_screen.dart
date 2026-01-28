import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'expense_list_screen.dart';
import 'income_list_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int fortnightOffset = 0;

  @override
  Widget build(BuildContext context) {
    final summary = StorageService.getDashboardSummary(fortnightOffset);
    final range = StorageService.getFortnightRange(fortnightOffset);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Budget Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigation to settings would go here
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Fortnight Navigation ---
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
                      Text("Fortnight Period", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        "${range['start']!.day}/${range['start']!.month} - ${range['end']!.day}/${range['end']!.month}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

            // --- Summary Cards ---
            _buildSummaryCard("Total Income", summary['income']!, Colors.teal),
            _buildSummaryCard("Total Expenses Paid", summary['expenses']!, Colors.blueGrey),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Divider(),
            ),
            
            _buildSummaryCard("Savings Cap", summary['savings']!, Colors.indigo),
            _buildSummaryCard("Remaining", summary['remaining']!, Colors.deepPurple),

            const SizedBox(height: 20),

            // --- CHART CARD (Matches your image) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Expenses by Category",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SfCircularChart(
                    legend: const Legend(
                      isVisible: true, 
                      position: LegendPosition.bottom,
                      overflowMode: LegendItemOverflowMode.wrap,
                    ),
                    palette: const <Color>[
                      Colors.teal, Colors.indigo, Colors.deepPurple, 
                      Colors.blueGrey, Colors.orange, Colors.redAccent
                    ],
                    series: <CircularSeries>[
                      DoughnutSeries<ChartData, String>(
                        dataSource: StorageService.getCategoryTotals(fortnightOffset),
                        xValueMapper: (ChartData data, _) => data.category,
                        yValueMapper: (ChartData data, _) => data.amount,
                        innerRadius: '70%',
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                          textStyle: TextStyle(fontSize: 10),
                        ),
                        enableTooltip: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- Navigation Buttons ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildNavButton(
                    context,
                    label: "Manage Expenses",
                    icon: Icons.receipt_long_outlined,
                    color: Colors.black87,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExpenseListScreen(fortnightOffset: fortnightOffset)),
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavButton(
                    context,
                    label: "Income Sources",
                    icon: Icons.account_balance_outlined,
                    color: Colors.black87,
                    isOutlined: true,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => IncomeListScreen(fortnightOffset: fortnightOffset)),
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onPressed, required Color color, bool isOutlined = false}) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color), 
          label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white), 
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double value, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 5)),
      ),
      child: ListTile(
        title: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        trailing: Text(
          "\$${value.toStringAsFixed(2)}",
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
