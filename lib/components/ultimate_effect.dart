import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class UltimateEffect extends PositionComponent {
  double timer = 0;
  final double life = 0.6; // Duration of the burst

  UltimateEffect({required Vector2 position}) : super(
    position: position,
    anchor: Anchor.center,
  );

  @override
  void render(Canvas canvas) {
    if (timer >= life) return;
    
    double progress = timer / life;
    
    // Easing out the expansion
    double easedProgress = 1.0 - (1.0 - progress) * (1.0 - progress);
    double currentRadius = 1500 * easedProgress; // Cover the whole screen

    Paint fillPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity((1.0 - progress).clamp(0.0, 1.0)*0.5)
      ..style = PaintingStyle.fill;
      
    Paint strokePaint = Paint()
      ..color = Colors.white.withOpacity((1.0 - progress).clamp(0.0, 1.0))
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
      removeFromParent();
    }
  }
}
