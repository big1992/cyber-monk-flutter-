import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import 'player.dart';
import '../systems/audio_system.dart';

enum PickupType { lightKarma, darkKarma, exp }

class Pickup extends PositionComponent with HasGameRef<CyberMonkGame>, CollisionCallbacks {
  final PickupType type;
  final double expValue; // Variable EXP reward per enemy type
  double timeAlive = 0;

  Pickup({
    required super.position,
    required this.type,
    this.expValue = 15,
  }) : super(
          size: Vector2(type == PickupType.exp && expValue >= 30 ? 16 : 10, type == PickupType.exp && expValue >= 30 ? 16 : 10),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    Color baseCol = Colors.white;
    if (type == PickupType.darkKarma) baseCol = Colors.purpleAccent;
    if (type == PickupType.exp) baseCol = Colors.cyanAccent;

    double pulse = 1.0 + 0.2 * sin(timeAlive * 5); // Pulsing logic

    Paint glow = Paint()
      ..color = baseCol
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawCircle(Offset(size.x/2, size.y/2), (size.x/2 + 2) * pulse, glow);
    canvas.drawCircle(Offset(size.x/2, size.y/2), (size.x/2 - 2) * pulse, Paint()..color = Colors.white);
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeAlive += dt;
    // Picks drop down slowly
    position.y += 50 * dt;

    if (position.y > gameRef.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player && !other.isDead) {
      AudioSystem.playSFX('reward.wav', volume: 0.3);
      // Apply effect
      if (type == PickupType.lightKarma) {
        gameRef.karmaSystem.addKarma(1);
      } else if (type == PickupType.darkKarma) {
        gameRef.karmaSystem.addKarma(-1);
      } else {
        gameRef.karmaSystem.addExp(expValue * gameRef.player.expMultiplier);
      }
      removeFromParent();
    }
  }
}
