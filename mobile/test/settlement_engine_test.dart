import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settlements/domain/settlement_engine.dart';

void main() {
  group('SettlementEngine', () {
    test('simplifies debts correctly for a simple cycle', () {
      // A owes B 100, B owes C 100
      // Net: A: -100, B: 0, C: +100
      final netBalances = {
        'A': -100.0,
        'B': 0.0,
        'C': 100.0,
      };

      final settlements = SettlementEngine.simplifyDebts(netBalances);

      expect(settlements.length, 1);
      expect(settlements[0].fromUser, 'A');
      expect(settlements[0].toUser, 'C');
      expect(settlements[0].amount, 100.0);
    });

    test('simplifies debts for unequal splits', () {
      // Net balances:
      // Raj: +1000
      // Amit: -400
      // Rahul: -600
      final netBalances = {
        'Raj': 1000.0,
        'Amit': -400.0,
        'Rahul': -600.0,
      };

      final settlements = SettlementEngine.simplifyDebts(netBalances);

      expect(settlements.length, 2);
      
      // Since it's a max heap for creditors and debtors, 
      // Rahul (-600) is the max debtor, Raj (+1000) is max creditor
      // 1. Rahul pays Raj 600
      // 2. Amit pays Raj 400
      final rahulSettle = settlements.firstWhere((s) => s.fromUser == 'Rahul');
      expect(rahulSettle.toUser, 'Raj');
      expect(rahulSettle.amount, 600.0);

      final amitSettle = settlements.firstWhere((s) => s.fromUser == 'Amit');
      expect(amitSettle.toUser, 'Raj');
      expect(amitSettle.amount, 400.0);
    });

    test('handles precision issues', () {
      final netBalances = {
        'A': -33.33,
        'B': -33.33,
        'C': 66.66,
      };

      final settlements = SettlementEngine.simplifyDebts(netBalances);
      
      expect(settlements.length, 2);
      expect(settlements.every((s) => s.amount == 33.33), isTrue);
    });
  });
}
