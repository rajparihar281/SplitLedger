import 'package:collection/collection.dart';

class Settlement {
  final String fromUser;
  final String toUser;
  final double amount;

  Settlement({
    required this.fromUser,
    required this.toUser,
    required this.amount,
  });

  @override
  String toString() => '$fromUser owes $toUser: $amount';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settlement &&
          runtimeType == other.runtimeType &&
          fromUser == other.fromUser &&
          toUser == other.toUser &&
          amount == other.amount;

  @override
  int get hashCode => fromUser.hashCode ^ toUser.hashCode ^ amount.hashCode;
}

class BalanceNode implements Comparable<BalanceNode> {
  final String userId;
  final double balance;

  BalanceNode(this.userId, this.balance);

  @override
  int compareTo(BalanceNode other) {
    // We want a max-heap behavior based on the absolute value of the balance.
    // However, for the settlement engine, we usually separate into creditors (positive)
    // and debtors (negative), and we want the max in both queues.
    return balance.abs().compareTo(other.balance.abs());
  }
}

class SettlementEngine {
  /// Calculates simplified settlements from a map of net balances.
  /// Positive balance: user is owed money (creditor).
  /// Negative balance: user owes money (debtor).
  ///
  /// Time Complexity: O(n log n) where n is the number of users.
  static List<Settlement> simplifyDebts(Map<String, double> netBalances) {
    // Separate into creditors (max heap) and debtors (max heap of absolute values).
    // Using PriorityQueue from collection package which is a min-heap by default.
    // To make it a max-heap, we invert the comparison logic.
    final creditors = PriorityQueue<BalanceNode>((a, b) => b.balance.compareTo(a.balance));
    final debtors = PriorityQueue<BalanceNode>((a, b) => b.balance.abs().compareTo(a.balance.abs()));

    for (final entry in netBalances.entries) {
      if (entry.value > 0.001) {
        creditors.add(BalanceNode(entry.key, entry.value));
      } else if (entry.value < -0.001) {
        debtors.add(BalanceNode(entry.key, entry.value));
      }
    }

    final settlements = <Settlement>[];

    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      final creditor = creditors.removeFirst();
      final debtor = debtors.removeFirst();

      final settleAmount = creditor.balance < debtor.balance.abs()
          ? creditor.balance
          : debtor.balance.abs();

      // Ensure precision issues don't create 0.00 settlements
      if (settleAmount > 0.001) {
        settlements.add(Settlement(
          fromUser: debtor.userId,
          toUser: creditor.userId,
          amount: double.parse(settleAmount.toStringAsFixed(2)),
        ));
      }

      final newCreditorBalance = creditor.balance - settleAmount;
      final newDebtorBalance = debtor.balance.abs() - settleAmount;

      if (newCreditorBalance > 0.001) {
        creditors.add(BalanceNode(creditor.userId, newCreditorBalance));
      }

      if (newDebtorBalance > 0.001) {
        // add it back as negative because it's a debtor
        debtors.add(BalanceNode(debtor.userId, -newDebtorBalance));
      }
    }

    return settlements;
  }
}
