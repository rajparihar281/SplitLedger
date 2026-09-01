import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../settlements/domain/settlement_engine.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Settlement> _settlements = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch Members
      final membersData = await supabase
          .from('group_members')
          .select('user_id, role, users(id, name, email)')
          .eq('group_id', widget.groupId);

      // 2. Fetch Expenses with Splits
      final expensesData = await supabase
          .from('expenses')
          .select('*, users!expenses_paid_by_fkey(name), expense_splits(*)')
          .eq('group_id', widget.groupId)
          .order('created_at', ascending: false);

      // 3. Fetch past Settlements
      final pastSettlements = await supabase
          .from('settlements')
          .select('*')
          .eq('group_id', widget.groupId);

      // Calculate Balances
      // A user's net balance = (Amount they paid for others) - (Their share of expenses) + (Settlements received) - (Settlements sent)
      final balances = <String, double>{};
      for (var m in membersData) {
        balances[m['user_id']] = 0.0;
      }

      for (var exp in expensesData) {
        final paidBy = exp['paid_by'];
        final totalAmount = double.parse(exp['amount'].toString());

        // Payer's balance increases by total amount first
        balances[paidBy] = (balances[paidBy] ?? 0) + totalAmount;

        // Then subtract everyone's share (including payer's own share)
        final splits = exp['expense_splits'] as List<dynamic>;
        for (var split in splits) {
          final userId = split['user_id'];
          final amount = double.parse(split['amount'].toString());
          balances[userId] = (balances[userId] ?? 0) - amount;
        }
      }

      // Apply past settlements
      for (var sett in pastSettlements) {
        final fromUser = sett['from_user'];
        final toUser = sett['to_user'];
        final amt = double.parse(sett['amount'].toString());
        // fromUser pays toUser, meaning fromUser's debt decreases (balance goes up)
        // toUser receives, so toUser's credit decreases (balance goes down)
        balances[fromUser] = (balances[fromUser] ?? 0) + amt;
        balances[toUser] = (balances[toUser] ?? 0) - amt;
      }

      final simplifications = SettlementEngine.simplifyDebts(balances);

      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(membersData);
          _expenses = List<Map<String, dynamic>>.from(expensesData);
          _settlements = simplifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getUserName(String userId) {
    final member = _members.firstWhere((m) => m['user_id'] == userId, orElse: () => {});
    return member['users']?['name'] ?? 'Unknown User';
  }

  Future<void> _recordSettlement(Settlement s) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('settlements').insert({
        'group_id': widget.groupId,
        'from_user': s.fromUser,
        'to_user': s.toUser,
        'amount': s.amount,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement recorded')),
      );
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.groupName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.coral),
              )
            : TabBarView(
                children: [
                  _buildExpensesTab(theme),
                  _buildBalancesTab(theme),
                  _buildMembersTab(theme),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final res = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddExpenseScreen(
                  groupId: widget.groupId,
                  groupMembers: _members,
                ),
              ),
            );
            if (res == true) {
              _fetchData();
            }
          },
          backgroundColor: AppColors.coral,
          foregroundColor: AppColors.white,
          elevation: 2,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  // ── Expenses Tab ─────────────────────────────────────────────
  Widget _buildExpensesTab(ThemeData theme) {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.slate.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'No expenses yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add an expense to start tracking.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      itemCount: _expenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
      itemBuilder: (context, index) {
        final exp = _expenses[index];
        final amount = exp['amount'].toString();
        final paidByName = exp['users']?['name'] ?? 'Unknown';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 20,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Description & payer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp['description'],
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Paid by $paidByName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '₹$amount',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Balances / Settlement Tab ────────────────────────────────
  Widget _buildBalancesTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settlement suggestions',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.slate,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          if (_settlements.isEmpty)
            // All settled
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: AppColors.sage.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.sage,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'All settled up!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.sage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _settlements.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
                itemBuilder: (context, index) {
                  final s = _settlements[index];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Who owes whom
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_getUserName(s.fromUser)} owes ${_getUserName(s.toUser)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '₹${s.amount}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Settle button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _recordSettlement(s),
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.sage,
                            ),
                            label: Text(
                              'Mark as settled',
                              style: TextStyle(color: AppColors.sage),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.sage.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                            ),
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
  }

  // ── Members Tab ──────────────────────────────────────────────
  Widget _buildMembersTab(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      itemCount: _members.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
      itemBuilder: (context, index) {
        final m = _members[index];
        final name = m['users']?['name'] ?? 'Unknown';
        final email = m['users']?['email'] ?? '';
        final role = m['role'] as String? ?? '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              // Muted avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Name & email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Role badge
              if (role.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(
                    role,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.slate,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
