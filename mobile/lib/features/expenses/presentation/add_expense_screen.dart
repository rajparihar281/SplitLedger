import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Amount (primary visual focus) ──────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '₹',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.slate,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate.withValues(alpha: 0.3),
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),
                    const Divider(),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Description ───────────────────────────
                    _buildFieldLabel('Expense name', theme),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Dinner at restaurant',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Paid by ───────────────────────────────
                    _buildFieldLabel('Paid by', theme),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPayerId,
                      decoration: const InputDecoration(),
                      dropdownColor: AppColors.white,
                      items: widget.groupMembers.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['user_id'],
                          child: Text(
                            m['users']?['name'] ?? 'Unknown User',
                            style: theme.textTheme.bodyLarge,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPayerId = val);
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Split type ────────────────────────────
                    _buildFieldLabel('Split type', theme),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
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
                    ),

                    const SizedBox(height: AppSpacing.base),

                    // ── Custom split fields ───────────────────
                    if (_splitType != 'equal')
                      ...widget.groupMembers.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              // Member name
                              Expanded(
                                child: Text(
                                  m['users']?['name'] ?? 'User',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              // Amount / percentage input
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  controller: _splitControllers[m['user_id']],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _splitType == 'unequal' ? '0.00' : '0',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    suffixText: _splitType == 'percentage' ? '%' : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── Save button ───────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveExpense,
                        child: const Text('Add expense'),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        color: AppColors.slate,
      ),
    );
  }
}
