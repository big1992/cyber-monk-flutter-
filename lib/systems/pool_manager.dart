import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'object_pool.dart';
import '../components/bullet.dart';
import '../components/enemy.dart';
import '../components/damage_text.dart';
import '../components/pickup.dart';
import '../components/ultimate_effect.dart';

/// Central Object Pool Manager
///
/// Holds one [ObjectPool] per poolable component type.
/// All spawn/release operations go through this class so the game never
/// calls `new Bullet(...)` directly; it always recycles a pooled instance.
///
/// Lifecycle:
///   1. [initialize] in CyberMonkGame.onLoad()
///   2. Use [spawnBullet], [spawnEnemy], etc. instead of game.add(Bullet(...))
///   3. Components call [releaseBullet], [releaseEnemy], etc. on destruction
class PoolManager {
  late final ObjectPool<Bullet> bulletPool;
  late final ObjectPool<Enemy> enemyPool;
  late final ObjectPool<DamageText> damageTextPool;
  late final ObjectPool<Pickup> pickupPool;
  late final ObjectPool<UltimateEffect> ultimateEffectPool;

  bool _initialized = false;

  void initialize() {
    assert(!_initialized, 'PoolManager.initialize() called more than once');
    _initialized = true;

    bulletPool = ObjectPool<Bullet>(
      create: Bullet.blank,
      maxSize: 120,
    )..prewarm(40);

    enemyPool = ObjectPool<Enemy>(
      create: Enemy.blank,
      maxSize: 30,
    )..prewarm(10);

    damageTextPool = ObjectPool<DamageText>(
      create: DamageText.blank,
      maxSize: 30,
    )..prewarm(10);

    pickupPool = ObjectPool<Pickup>(
      create: Pickup.blank,
      maxSize: 20,
    )..prewarm(5);

    ultimateEffectPool = ObjectPool<UltimateEffect>(
      create: UltimateEffect.blank,
      maxSize: 2,
    )..prewarm(1);
  }

  // ─────────────────────────── BULLET ────────────────────────────

  /// Acquires a pooled [Bullet], resets it, and adds it to [game].
  Bullet spawnBullet(
    FlameGame game, {
    required Vector2 position,
    required Vector2 velocity,
    required double damage,
    bool isPlayerOwned = true,
    Color paintColor = Colors.yellow,
    int piercesRemaining = 0,
    int bouncesRemaining = 0,
    bool isHoming = false,
    bool isCleansing = false,
    double dotPct = 0.0,
    bool isIce = false,
    bool isFire = false,
  }) {
    final bullet = bulletPool.acquire();
    bullet.resetForPool(
      position: position,
      velocity: velocity,
      damage: damage,
      isPlayerOwned: isPlayerOwned,
      paintColor: paintColor,
      piercesRemaining: piercesRemaining,
      bouncesRemaining: bouncesRemaining,
      isHoming: isHoming,
      isCleansing: isCleansing,
      dotPct: dotPct,
      isIce: isIce,
      isFire: isFire,
    );
    game.add(bullet);
    return bullet;
  }

  /// Returns [bullet] to the pool and removes it from the game tree.
  void releaseBullet(Bullet bullet) {
    bulletPool.release(bullet);
    bullet.removeFromParent();
  }

  // ─────────────────────────── ENEMY ─────────────────────────────

  /// Acquires a pooled [Enemy], resets it, and adds it to [game].
  Enemy spawnEnemy(
    FlameGame game, {
    required Vector2 position,
    required EnemyType type,
    double waveMultiplier = 1.0,
  }) {
    final enemy = enemyPool.acquire();
    enemy.resetForPool(
      position: position,
      type: type,
      waveMultiplier: waveMultiplier,
    );
    game.add(enemy);
    return enemy;
  }

  /// Returns [enemy] to the pool and removes it from the game tree.
  void releaseEnemy(Enemy enemy) {
    enemyPool.release(enemy);
    enemy.removeFromParent();
  }

  // ─────────────────────────── DAMAGE TEXT ───────────────────────

  /// Acquires a pooled [DamageText], resets it, and adds it to [game].
  DamageText spawnDamageText(
    FlameGame game, {
    required String text,
    required Vector2 position,
    bool isCritical = false,
  }) {
    final dt = damageTextPool.acquire();
    dt.resetForPool(text: text, position: position, isCritical: isCritical);
    game.add(dt);
    return dt;
  }

  /// Returns [dt] to the pool and removes it from the game tree.
  void releaseDamageText(DamageText dt) {
    damageTextPool.release(dt);
    dt.removeFromParent();
  }

  // ─────────────────────────── PICKUP ────────────────────────────

  /// Acquires a pooled [Pickup], resets it, and adds it to [game].
  Pickup spawnPickup(
    FlameGame game, {
    required Vector2 position,
    required PickupType type,
    double expValue = 15,
  }) {
    final pickup = pickupPool.acquire();
    pickup.resetForPool(position: position, type: type, expValue: expValue);
    game.add(pickup);
    return pickup;
  }

  /// Returns [pickup] to the pool and removes it from the game tree.
  void releasePickup(Pickup pickup) {
    pickupPool.release(pickup);
    pickup.removeFromParent();
  }

  // ─────────────────────────── ULTIMATE EFFECT ───────────────────

  /// Acquires a pooled [UltimateEffect], resets it, and adds it to [game].
  UltimateEffect spawnUltimateEffect(FlameGame game, {required Vector2 position}) {
    final effect = ultimateEffectPool.acquire();
    effect.resetForPool(position: position);
    game.add(effect);
    return effect;
  }

  /// Returns [effect] to the pool and removes it from the game tree.
  void releaseUltimateEffect(UltimateEffect effect) {
    ultimateEffectPool.release(effect);
    effect.removeFromParent();
  }
}
