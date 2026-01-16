import 'package:flutter/material.dart';
import '../models/frequency.dart';

class EditItemScreen extends StatefulWidget {
  final String title;
  final String name;
  final String category;
  final double amount;
  final Frequency frequency;
  final void Function(String, String, double, Frequency) onSave;

  const EditItemScreen({
    super.key,
    required this.title,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.onSave,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController amountCtrl;
  late Frequency freq;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name);
    categoryCtrl = TextEditingController(text: widget.category);
    amountCtrl = TextEditingController(text: widget.amount.toString());
    freq = widget.frequency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            DropdownButton<Frequency>(
              value: freq,
              items: Frequency.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (v) => setState(() => freq = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onSave(
                  nameCtrl.text,
                  categoryCtrl.text,
                  double.parse(amountCtrl.text),
                  freq,
                );
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
