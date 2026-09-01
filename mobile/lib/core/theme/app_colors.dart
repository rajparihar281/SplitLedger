import 'package:flutter/material.dart';

/// SplitLedger — Warm Finance / Modern Personal Ledger palette.
///
/// Ink  → structure
/// Coral → action
/// Sage  → completed / positive
/// Amber → pending / attention
/// Error → destructive
/// Slate → supporting information
/// Paper → environment
/// White → content surfaces
/// Mist  → inputs / secondary surfaces
/// Border → separation
class AppColors {
  AppColors._();

  // ── Foundation ──────────────────────────────────────────────
  /// Primary text, headings, important amounts, primary buttons.
  static const ink = Color(0xFF252A34);

  /// Warm off-white scaffold / background.
  static const paper = Color(0xFFFAF8F5);

  /// Card and elevated-surface background.
  static const white = Color(0xFFFFFFFF);

  /// Inputs, secondary surfaces.
  static const mist = Color(0xFFF0EFEC);

  /// Secondary text, metadata, inactive icons, helper text.
  static const slate = Color(0xFF777B83);

  /// Subtle borders, dividers, card outlines.
  static const border = Color(0xFFE3E0DA);

  // ── Brand Accent ────────────────────────────────────────────
  /// Primary accent — used sparingly for actions, FABs, selected state.
  static const coral = Color(0xFFE9826E);

  // ── Semantic Colors ─────────────────────────────────────────
  /// Settled, paid, completed, positive states.
  static const sage = Color(0xFF789C86);

  /// Pending, reminder, needs-attention states.
  static const amber = Color(0xFFD9A441);

  /// Failed, destructive, overdue states.
  static const error = Color(0xFFC96B67);
}
