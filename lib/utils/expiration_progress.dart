import 'package:flutter/material.dart';

/// How much of an item's ~30-day shelf-life window remains, plus the color
/// that should be used to represent that in a progress bar. Shared by the
/// pantry list and category detail screens so the calculation only lives
/// in one place.
class ExpirationProgress {
  final double value;
  final Color color;

  const ExpirationProgress(this.value, this.color);

  factory ExpirationProgress.of(DateTime expirationDate, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final remainingSeconds = expirationDate.difference(currentTime).inSeconds;
    final totalDuration = remainingSeconds > 0 ? remainingSeconds : 0;
    final windowSeconds = expirationDate.difference(currentTime.subtract(const Duration(days: 30))).inSeconds;
    final initialDuration = windowSeconds > 0 ? windowSeconds : 1;
    final progress = (totalDuration / initialDuration).clamp(0.0, 1.0);
    final color = progress > 0.5 ? Colors.green : (progress > 0.2 ? Colors.orange : Colors.red);
    return ExpirationProgress(progress, color);
  }
}
