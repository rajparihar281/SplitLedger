import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final List<Map<String, dynamic>> groupMembers;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  String? _selectedPayerId;
  String _splitType = 'equal'; // 'equal', 'unequal', 'percentage'
  
  final Map<String, TextEditingController> _splitControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPayerId = Supabase.instance.client.auth.currentUser!.id;
    for (var member in widget.groupMembers) {
      _splitControllers[member['user_id']] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amountText = _amountController.text.trim();
    final double? totalAmount = double.tryParse(amountText);
    if (totalAmount == null || totalAmount <= 0) {
      _showError('Invalid amount');
      return;
    }

    final Map<String, double> finalSplits = {};
    if (_splitType == 'equal') {
      final splitAmount = totalAmount / widget.groupMembers.length;
      for (var member in widget.groupMembers) {
        finalSplits[member['user_id']] = double.parse(splitAmount.toStringAsFixed(2));
      }
    } else if (_splitType == 'unequal') {
      double sum = 0;
      for (var member in widget.groupMembers) {
        final val = double.tryParse(_splitControllers[member['user_id']]!.text) ?? 0;
        sum += val;
        finalSplits[member['user_id']] = val;
      }
      if ((sum - totalAmount).abs() > 0.05) {
        _showError('Unequal amounts must sum up to total ($totalAmount). Currently sums to $sum');
        return;
      }
    } else if (_splitType == 'percentage') {
      double pctSum = 0;
      for (var member in widget.groupMembers) {
        final pct = double.tryParse(_splitControllers[member['user_id']]!.text) ?? 0;
        pctSum += pct;
        final val = (pct / 100.0) * totalAmount;
        finalSplits[member['user_id']] = double.parse(val.toStringAsFixed(2));
      }
      if ((pctSum - 100.0).abs() > 0.05) {
        _showError('Percentages must sum up to 100%. Currently sums to $pctSum%');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final expenseRes = await supabase.from('expenses').insert({
        'group_id': widget.groupId,
        'paid_by': _selectedPayerId,
        'created_by': userId,
        'description': _descriptionController.text.trim(),
        'amount': totalAmount,
      }).select().single();

      final expenseId = expenseRes['id'];

      final splitInserts = finalSplits.entries
          .where((e) => e.value > 0)
          .map((e) => {
                'expense_id': expenseId,
                'user_id': e.key,
                'amount': e.value,
              })
          .toList();

      await supabase.from('expense_splits').insert(splitInserts);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showError('Error adding expense: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPayerId,
                      decoration: const InputDecoration(labelText: 'Paid By'),
                      items: widget.groupMembers.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['user_id'],
                          child: Text(m['users']?['name'] ?? 'Unknown User'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPayerId = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Split Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'equal', label: Text('Equal')),
                        ButtonSegment(value: 'unequal', label: Text('Unequal')),
                        ButtonSegment(value: 'percentage', label: Text('%')),
                      ],
                      selected: {_splitType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _splitType = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_splitType != 'equal')
                      ...widget.groupMembers.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(m['users']?['name'] ?? 'User')),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  controller: _splitControllers[m['user_id']],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: _splitType == 'unequal' ? 'Amount' : '%',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveExpense,
                        child: const Text('Save Expense'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
