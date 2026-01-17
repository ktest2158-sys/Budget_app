import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/income.dart';
import '../models/frequency.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class IncomeListScreen extends StatefulWidget {
  final int fortnightOffset;
  const IncomeListScreen({super.key, required this.fortnightOffset});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  @override
  Widget build(BuildContext context) {
    final range = StorageService.getFortnightRange(widget.fortnightOffset);
    
    // 1. Get ONLY income records for this specific fortnight
    final allIncomes = StorageService.getIncomes();
    final receivedThisFortnight = allIncomes.where((inc) => 
      inc.date.isAfter(range['start']!.subtract(const Duration(seconds: 1))) && 
      inc.date.isBefore(range['end']!.add(const Duration(seconds: 1)))
    ).toList();

    // 2. Get the Master Checklist (Items with the appStartDate)
    // Filter out items that have already been "received" this fortnight
    final expectedChecklist = allIncomes.where((inc) => 
      inc.date == StorageService.appStartDate
    ).where((master) {
      bool alreadyReceived = receivedThisFortnight.any((received) => received.name == master.name);
      return !alreadyReceived;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Income')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addIncome(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          // --- MASTER CHECKLIST ---
          if (expectedChecklist.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text("EXPECTED THIS FORTNIGHT", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
            ),
            ...expectedChecklist.map((master) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.radio_button_unchecked, color: Colors.blue),
                title: Text(master.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text("\$${master.amount.toStringAsFixed(2)}"),
                onTap: () async {
                  // ✅ Tapping marks it as received and hides it from this list
                  await StorageService.checkOffIncome(master, widget.fortnightOffset);
                  setState(() {}); 
                },
              ),
            )),
          ],

          const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),

          // --- RECEIVED LIST ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text("RECEIVED", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
          ),
          if (receivedThisFortnight.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Waiting for income...", style: TextStyle(color: Colors.grey)),
            )),
          ...receivedThisFortnight.map((income) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(income.name, style: const TextStyle(color: Colors.grey)),
            subtitle: Text("\$${income.amount.toStringAsFixed(2)}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                await StorageService.deleteIncome(income.id);
                setState(() {}); // Deleting here makes it pop back into the "Expected" list
              },
            ),
            onTap: () => _editIncome(context, income),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _addIncome(BuildContext context) {
    final range = StorageService.getFortnightRange(widget.fortnightOffset);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddItemScreen(
        title: 'Add Income',
        onSave: (name, category, amount, freq) async {
          await StorageService.saveIncome(Income(
            name: name, category: category, amount: amount, 
            frequency: freq, date: range['start']!,
          ));
          setState(() {});
        },
      ),
    ));
  }

  void _editIncome(BuildContext context, Income income) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EditItemScreen(
        title: 'Edit Income',
        name: income.name,
        category: income.category,
        amount: income.amount,
        frequency: income.frequency,
        onSave: (name, category, amount, freq) async {
          final updated = Income(
            id: income.id, name: name, category: category, 
            amount: amount, frequency: freq, date: income.date,
          );
          await StorageService.saveIncome(updated);
          setState(() {});
        },
      ),
    ));
  }
}