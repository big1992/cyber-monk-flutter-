import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class DamageText extends PositionComponent {
  final String _text;
  final Color _color;
  final double _fontSize;

  double life = 0.8;
  double timer = 0;

  // Pre-built painters — created ONCE, not every frame
  late final TextPainter _painter;

  DamageText({
    required String text,
    required Vector2 position,
    bool isCritical = false,
  })  : _text = text,
        _color = isCritical ? Colors.yellowAccent : Colors.redAccent,
        _fontSize = isCritical ? 24 : 16,
        super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
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

    // Float upwards via Flame effect (no per-frame overhead)
    add(MoveByEffect(
      Vector2(0, -50),
      EffectController(duration: life, curve: Curves.easeOut),
    ));
  }

  @override
  void render(Canvas canvas) {
    if (timer >= life) return;
    double opacity = (1.0 - (timer / life)).clamp(0.0, 1.0);
    canvas.saveLayer(null, Paint()..color = Color.fromARGB((opacity * 255).toInt(), 255, 255, 255));
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    timer += dt;
    if (timer >= life) {
      removeFromParent();
    }
  }
}
