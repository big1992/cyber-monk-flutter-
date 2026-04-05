import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';

/// Full-screen cyan burst that plays when the player activates the Ultimate.
///
/// Supports object pooling: call [resetForPool] before re-adding to the game.
class UltimateEffect extends PositionComponent with HasGameRef<CyberMonkGame> {
  double timer = 0;
  final double life = 0.6;

  // ─── Regular constructor ──────────────────────────────────────────
  UltimateEffect({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  /// Blank factory used by [ObjectPool].
  UltimateEffect.blank() : super(anchor: Anchor.center);

  // ─── Pool reset ───────────────────────────────────────────────────

  /// Called by [PoolManager.spawnUltimateEffect] before re-adding.
  void resetForPool({required Vector2 position}) {
    this.position = position;
    timer = 0;
  }

  // ─── Flame lifecycle ──────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (timer >= life) return;

    double progress = timer / life;
    double easedProgress = 1.0 - (1.0 - progress) * (1.0 - progress);
    double currentRadius = 1500 * easedProgress;

    Paint fillPaint = Paint()
      ..color = Colors.cyanAccent
          .withOpacity((1.0 - progress).clamp(0.0, 1.0) * 0.5)
      ..style = PaintingStyle.fill;

    Paint strokePaint = Paint()
      ..color =
          Colors.white.withOpacity((1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20 * (1.0 - progress);

    canvas.drawCircle(Offset.zero, currentRadius, fillPaint);
    canvas.drawCircle(Offset.zero, currentRadius, strokePaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    timer += dt;
    if (timer >= life) {
      _releaseToPool();
    }
  }

  // ─── Internal helper ──────────────────────────────────────────────

  void _releaseToPool() {
    gameRef.poolManager.releaseUltimateEffect(this);
  }
}
