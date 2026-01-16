import 'package:flutter/material.dart';
import '../models/frequency.dart';

class AddItemScreen extends StatefulWidget {
  final String title;
  final void Function(String, String, double, Frequency) onSave;

  const AddItemScreen({
    super.key,
    required this.title,
    required this.onSave,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final nameCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  Frequency freq = Frequency.weekly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            DropdownButton<Frequency>(
              value: freq,
              items: Frequency.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label),
                      ))
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
