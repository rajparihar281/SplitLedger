import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      for(var sett in pastSettlements) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settlement recorded!')));
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Expenses Tab
                  _buildExpensesTab(),
                  // Balances Tab
                  _buildBalancesTab(),
                  // Members Tab
                  _buildMembersTab(),
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
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }
    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final exp = _expenses[index];
        return ListTile(
          title: Text(exp['description']),
          subtitle: Text('Paid by ${exp['users']?['name'] ?? 'Unknown'}'),
          trailing: Text('₹${exp['amount']}'),
        );
      },
    );
  }

  Widget _buildBalancesTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Settlement Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (_settlements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('All settled up!'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _settlements.length,
              itemBuilder: (context, index) {
                final s = _settlements[index];
                return ListTile(
                  title: Text('${_getUserName(s.fromUser)} owes ${_getUserName(s.toUser)}'),
                  trailing: Text('₹${s.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: TextButton(
                    onPressed: () => _recordSettlement(s),
                    child: const Text('Record Settlement'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final m = _members[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(m['users']?['name'] ?? 'Unknown'),
          subtitle: Text(m['users']?['email'] ?? ''),
          trailing: Text(m['role']),
        );
      },
    );
  }
}
