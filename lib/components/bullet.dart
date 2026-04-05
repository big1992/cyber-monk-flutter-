import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import 'boss.dart';
import 'enemy.dart';
import 'player.dart';

class Bullet extends RectangleComponent
    with HasGameRef<CyberMonkGame>, CollisionCallbacks {
  // ─── mutable state (reset on every pool cycle) ───────────────────
  Vector2 velocity;
  double damage;
  bool isPlayerOwned;
  int piercesRemaining;
  int bouncesRemaining;
  bool isHoming;
  bool isCleansing;
  double dotPct;
  bool isIce;
  bool isFire;

  // Trail
  final List<Vector2> _trail = [];
  double _trailTimer = 0;

  // Failsafe lifespan
  double _lifespan = 5.0;

  // Pre-cached paints (refreshed in resetForPool)
  Paint _glowPaint = Paint();
  Paint _corePaint = Paint()..color = Colors.white;
  Rect _glowRect = Rect.zero;

  // Pool guard — ensures hitbox is only added once
  bool _poolInitialized = false;
  late RectangleHitbox _hitbox;

  // ─── Regular constructor (kept for backward compat if needed) ────
  Bullet({
    required super.position,
    required this.velocity,
    required this.damage,
    this.isPlayerOwned = true,
    Color paintColor = Colors.yellow,
    this.piercesRemaining = 0,
    this.bouncesRemaining = 0,
    this.isHoming = false,
    this.isCleansing = false,
    this.dotPct = 0.0,
    this.isIce = false,
    this.isFire = false,
  }) : super(
          size: isCleansing ? Vector2(100, 10) : Vector2(10, 10),
          anchor: Anchor.center,
        ) {
    paint = Paint()..color = paintColor;
  }

  /// Blank factory used by [ObjectPool] to pre-create instances.
  Bullet.blank()
      : velocity = Vector2.zero(),
        damage = 0,
        isPlayerOwned = true,
        piercesRemaining = 0,
        bouncesRemaining = 0,
        isHoming = false,
        isCleansing = false,
        dotPct = 0.0,
        isIce = false,
        isFire = false,
        super(
          size: Vector2(10, 10),
          anchor: Anchor.center,
        ) {
    paint = Paint()..color = Colors.yellow;
  }

  // ─── Pool reset ──────────────────────────────────────────────────

  /// Called by [PoolManager.spawnBullet] before re-adding to the game tree.
  void resetForPool({
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
    this.position = position;
    this.velocity = velocity;
    this.damage = damage;
    this.isPlayerOwned = isPlayerOwned;
    this.piercesRemaining = piercesRemaining;
    this.bouncesRemaining = bouncesRemaining;
    this.isHoming = isHoming;
    this.isCleansing = isCleansing;
    this.dotPct = dotPct;
    this.isIce = isIce;
    this.isFire = isFire;

    // Size & hitbox
    size = isCleansing ? Vector2(100, 10) : Vector2(10, 10);
    if (_poolInitialized) _hitbox.size = size;

    // Paints
    paint = Paint()..color = paintColor;
    _glowPaint = Paint()..color = paintColor.withOpacity(0.4);
    _corePaint = Paint()..color = Colors.white;
    _glowRect = size.toRect().inflate(4.0);

    // Timers
    _lifespan = 5.0;
    _trailTimer = 0;
    _trail.clear();
  }

  // ─── Flame lifecycle ─────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    if (_poolInitialized) return; // Re-add from pool: skip re-setup
    _poolInitialized = true;

    _hitbox = RectangleHitbox();
    add(_hitbox);

    // Initial paint cache (may be overwritten by resetForPool)
    _glowPaint = Paint()..color = paint.color.withOpacity(0.4);
    _corePaint = Paint()..color = Colors.white;
    _glowRect = size.toRect().inflate(4.0);
  }

  @override
  void render(Canvas canvas) {
    // Draw trail (max 4 segments for mobile)
    if (_trail.length > 1) {
      final int len = _trail.length;
      for (int i = 0; i < len - 1; i++) {
        double progress = (i + 1) / len;
        final Paint trailP = Paint()
          ..color = paint.color.withOpacity(0.4 * progress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCleansing ? 8 * progress : 4 * progress;
        Vector2 startP = _trail[i] - position + size / 2;
        Vector2 endP = _trail[i + 1] - position + size / 2;
        canvas.drawLine(startP.toOffset(), endP.toOffset(), trailP);
      }
    }

    // Draw main projectile (cached paints)
    if (isCleansing) {
      canvas.drawRect(_glowRect, _glowPaint);
      canvas.drawRect(size.toRect(), _corePaint);
    } else if (isHoming) {
      final Path p = Path();
      p.moveTo(size.x / 2, 0);
      p.lineTo(size.x, size.y / 2);
      p.lineTo(size.x / 2, size.y);
      p.lineTo(0, size.y / 2);
      p.close();
      canvas.drawPath(p, _glowPaint);
      canvas.drawPath(p, _corePaint);
    } else {
      canvas.drawRect(_glowRect, _glowPaint);
      canvas.drawRect(size.toRect(), _corePaint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      _releaseToPool();
      return;
    }

    // Homing logic
    if (isHoming && isPlayerOwned) {
      double minD2 = double.infinity;
      Enemy? nearest;
      for (final enemy in gameRef.children.whereType<Enemy>()) {
        if (!enemy.isDead) {
          double d2 = enemy.position.distanceToSquared(position);
          if (d2 < minD2) {
            minD2 = d2;
            nearest = enemy;
          }
        }
      }
      if (nearest != null) {
        Vector2 dir = (nearest.position - position).normalized();
        velocity.lerp(dir * velocity.length, dt * 5.0);
      }
    }

    position.add(velocity * dt);

    // Track trail — max 4 points on mobile
    _trailTimer += dt;
    if (_trailTimer > 0.04) {
      _trailTimer = 0;
      _trail.add(position.clone());
      if (_trail.length > 4) _trail.removeAt(0);
    }

    // Bounce / screen-exit logic
    if (bouncesRemaining > 0) {
      if (position.x <= 0) {
        velocity.x = velocity.x.abs();
        bouncesRemaining--;
      } else if (position.x >= gameRef.size.x) {
        velocity.x = -velocity.x.abs();
        bouncesRemaining--;
      }
      if (position.y <= 0) {
        velocity.y = velocity.y.abs();
        bouncesRemaining--;
      } else if (position.y >= gameRef.size.y) {
        velocity.y = -velocity.y.abs();
        bouncesRemaining--;
      }
    } else {
      if (position.y < -50 ||
          position.y > gameRef.size.y + 50 ||
          position.x < -50 ||
          position.x > gameRef.size.x + 50) {
        _releaseToPool();
      }
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (isPlayerOwned) {
      if (other is Enemy && !other.isDead) {
        other.takeDamage(damage, dotPct: dotPct, isIce: isIce, isFire: isFire);
        if (piercesRemaining > 0) {
          piercesRemaining--;
        } else {
          _releaseToPool();
        }
      } else if (other is Boss && !other.isDead) {
        other.takeDamage(damage);
        if (piercesRemaining > 0) {
          piercesRemaining--;
        } else {
          _releaseToPool();
        }
      } else if (isCleansing && other is Bullet && !other.isPlayerOwned) {
        // Particle burst when cleansing
        gameRef.add(ParticleSystemComponent(
            position: other.position.clone(),
            particle: Particle.generate(
                count: 5,
                lifespan: 0.2,
                generator: (i) => AcceleratedParticle(
                    speed: Vector2.random() * 100,
                    child: CircleParticle(
                        radius: 2, paint: Paint()..color = Colors.white)))));
        other._releaseToPool();
      }
    } else if (!isPlayerOwned && other is Player) {
      if (!other.isDead) {
        other.takeDamage(damage);
        _releaseToPool();
      }
    }
  }

  // ─── Internal helper ─────────────────────────────────────────────

  void _releaseToPool() {
    gameRef.poolManager.releaseBullet(this);
  }
}
