import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import 'player.dart';
import '../systems/audio_system.dart';

enum PickupType { lightKarma, darkKarma, exp }

class Pickup extends PositionComponent
    with HasGameRef<CyberMonkGame>, CollisionCallbacks {
  PickupType type;
  double expValue;
  double timeAlive = 0;

  // Pool guard
  bool _poolInitialized = false;
  late RectangleHitbox _hitbox;

  // ─── Regular constructor ──────────────────────────────────────────
  Pickup({
    required super.position,
    required this.type,
    this.expValue = 15,
  }) : super(
          size: Vector2(
            type == PickupType.exp && expValue >= 30 ? 16 : 10,
            type == PickupType.exp && expValue >= 30 ? 16 : 10,
          ),
          anchor: Anchor.center,
        );

  /// Blank factory used by [ObjectPool].
  Pickup.blank()
      : type = PickupType.exp,
        expValue = 15,
        super(size: Vector2(10, 10), anchor: Anchor.center);

  // ─── Pool reset ───────────────────────────────────────────────────

  /// Called by [PoolManager.spawnPickup] before re-adding to the game tree.
  void resetForPool({
    required Vector2 position,
    required PickupType type,
    double expValue = 15,
  }) {
    this.position = position;
    this.type = type;
    this.expValue = expValue;
    timeAlive = 0;

    // Resize based on type/value
    final s = (type == PickupType.exp && expValue >= 30) ? 16.0 : 10.0;
    size = Vector2(s, s);
    if (_poolInitialized) _hitbox.size = size;
  }

  // ─── Flame lifecycle ──────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    if (_poolInitialized) return;
    _poolInitialized = true;

    _hitbox = RectangleHitbox();
    add(_hitbox);
  }

  @override
  void render(Canvas canvas) {
    Color baseCol = Colors.white;
    if (type == PickupType.darkKarma) baseCol = Colors.purpleAccent;
    if (type == PickupType.exp) baseCol = Colors.cyanAccent;

    double pulse = 1.0 + 0.2 * sin(timeAlive * 5);

    Paint glow = Paint()
      ..color = baseCol
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), (size.x / 2 + 2) * pulse, glow);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), (size.x / 2 - 2) * pulse,
        Paint()..color = Colors.white);
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeAlive += dt;
    position.y += 50 * dt;

    if (position.y > gameRef.size.y + 50) {
      _releaseToPool();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player && !other.isDead) {
      AudioSystem.playSFX('reward.wav', volume: 0.3);
      if (type == PickupType.lightKarma) {
        gameRef.karmaSystem.addKarma(1);
      } else if (type == PickupType.darkKarma) {
        gameRef.karmaSystem.addKarma(-1);
      } else {
        gameRef.karmaSystem
            .addExp(expValue * gameRef.player.expMultiplier);
      }
      _releaseToPool();
    }
  }

  // ─── Internal helper ──────────────────────────────────────────────

  void _releaseToPool() {
    gameRef.poolManager.releasePickup(this);
  }
}
