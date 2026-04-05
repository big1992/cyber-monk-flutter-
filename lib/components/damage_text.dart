import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';

/// Floating damage number that rises and fades out.
///
/// Supports object pooling: call [resetForPool] before re-adding to the game.
/// The [TextPainter] is rebuilt every time the component is mounted so that
/// new text/colour is applied correctly on pool reuse.
class DamageText extends PositionComponent with HasGameRef<CyberMonkGame> {
  String _text;
  Color _color;
  double _fontSize;

  double life = 0.8;
  double timer = 0;

  late TextPainter _painter;

  // Pool guard — hitbox/painter only fully init once
  bool _poolInitialized = false;

  // ─── Regular constructor ──────────────────────────────────────────
  DamageText({
    required String text,
    required Vector2 position,
    bool isCritical = false,
  })  : _text = text,
        _color = isCritical ? Colors.yellowAccent : Colors.redAccent,
        _fontSize = isCritical ? 24 : 16,
        super(position: position, anchor: Anchor.center);

  /// Blank factory used by [ObjectPool].
  DamageText.blank()
      : _text = '0',
        _color = Colors.redAccent,
        _fontSize = 16,
        super(anchor: Anchor.center);

  // ─── Pool reset ───────────────────────────────────────────────────

  /// Called by [PoolManager.spawnDamageText] before re-adding to the game tree.
  void resetForPool({
    required String text,
    required Vector2 position,
    bool isCritical = false,
  }) {
    _text = text;
    _color = isCritical ? Colors.yellowAccent : Colors.redAccent;
    _fontSize = isCritical ? 24 : 16;
    this.position = position;
    timer = 0;
    life = 0.8;
  }

  // ─── Flame lifecycle ──────────────────────────────────────────────

  /// [onMount] is called every time the component enters the game tree,
  /// including on pool re-use. We rebuild the painter and effects here.
  @override
  void onMount() {
    super.onMount();
    _rebuildPainterAndEffect();
  }

  void _rebuildPainterAndEffect() {
    // Rebuild TextPainter with current text/style
    _painter = TextPainter(
      text: TextSpan(
        text: _text,
        style: TextStyle(
          color: _color,
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Remove any leftover MoveByEffect from a previous pool cycle
    for (final child in List.of(children)) {
      if (child is MoveByEffect) remove(child);
    }

    // Float upwards via Flame effect
    add(MoveByEffect(
      Vector2(0, -50),
      EffectController(duration: life, curve: Curves.easeOut),
    ));

    _poolInitialized = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_poolInitialized || timer >= life) return;
    double opacity = (1.0 - (timer / life)).clamp(0.0, 1.0);
    canvas.saveLayer(
        null, Paint()..color = Color.fromARGB((opacity * 255).toInt(), 255, 255, 255));
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
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
    gameRef.poolManager.releaseDamageText(this);
  }
}
