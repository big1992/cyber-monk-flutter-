import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class DamageText extends TextComponent {
  DamageText({
    required String text,
    required Vector2 position,
    bool isCritical = false,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: isCritical ? Colors.yellowAccent : Colors.redAccent,
              fontSize: isCritical ? 24 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              shadows: [
                Shadow(
                  color: isCritical ? Colors.orange : Colors.black,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );

  double life = 0.8;
  double timer = 0;
  late final Color _baseColor;

  @override
  Future<void> onLoad() async {
    _baseColor = (textRenderer as TextPaint).style.color!;
    
    // Float upwards
    add(MoveByEffect(
      Vector2(0, -50),
      EffectController(duration: life, curve: Curves.easeOut),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    timer += dt;
    if (timer >= life) {
      removeFromParent();
    } else {
      double opacity = 1.0 - (timer / life);
      textRenderer = TextPaint(
        style: (textRenderer as TextPaint).style.copyWith(
              color: _baseColor.withOpacity(opacity.clamp(0.0, 1.0)),
            ),
      );
    }
  }
}
