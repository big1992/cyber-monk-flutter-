import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import 'boss.dart';
import 'enemy.dart';
import 'player.dart';

class Bullet extends RectangleComponent with HasGameRef<CyberMonkGame>, CollisionCallbacks {
  Vector2 velocity;
  final double damage;
  final bool isPlayerOwned;
  
  // New Skills properties
  int piercesRemaining;
  int bouncesRemaining;
  bool isHoming;
  bool isCleansing;
  double dotPct;
  bool isIce;
  bool isFire;
  
  // Trail System
  final List<Vector2> _trail = [];
  double _trailTimer = 0;

  // Pre-cached Paints for render performance
  late Paint _glowPaint;
  late Paint _corePaint;
  late Rect _glowRect;
  
  // Failsafe Lifespan
  double _lifespan = 5.0;
  
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

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    // Pre-cache paint objects to avoid allocation every frame
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
              Vector2 startP = _trail[i] - position + size/2;
              Vector2 endP = _trail[i+1] - position + size/2;
              canvas.drawLine(startP.toOffset(), endP.toOffset(), trailP);
          }
      }

      // Draw Main Projectile (cached paints)
      if (isCleansing) {
          canvas.drawRect(_glowRect, _glowPaint);
          canvas.drawRect(size.toRect(), _corePaint);
      } else if (isHoming) {
          final Path p = Path();
          p.moveTo(size.x/2, 0); p.lineTo(size.x, size.y/2); p.lineTo(size.x/2, size.y); p.lineTo(0, size.y/2); p.close();
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
      removeFromParent();
      return;
    }

    // Homing logic
    if (isHoming && isPlayerOwned) {
      // Find nearest enemy
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
          velocity.lerp(dir * velocity.length, dt * 5.0); // smooth turning
      }
    }
    
    position.add(velocity * dt);

    // Track trail - only 4 points max on mobile
    _trailTimer += dt;
    if (_trailTimer > 0.04) {
        _trailTimer = 0;
        _trail.add(position.clone());
        if (_trail.length > 4) {
            _trail.removeAt(0);
        }
    }

    // Bounce logic
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
        // Remove if off screen
        if (position.y < -50 || position.y > gameRef.size.y + 50 || position.x < -50 || position.x > gameRef.size.x + 50) {
          removeFromParent();
        }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (isPlayerOwned) {
        if (other is Enemy && !other.isDead) {
            other.takeDamage(damage, dotPct: dotPct, isIce: isIce, isFire: isFire);
            if (piercesRemaining > 0) {
                piercesRemaining--;
            } else {
                removeFromParent();
            }
        } else if (other is Boss && !other.isDead) {
            other.takeDamage(damage);
            if (piercesRemaining > 0) {
                piercesRemaining--;
            } else {
                removeFromParent();
            }
        } else if (isCleansing && other is Bullet && !other.isPlayerOwned) {
            // Particle burst when cleansing
            gameRef.add(ParticleSystemComponent(
               position: other.position.clone(),
               particle: Particle.generate(count: 5, lifespan: 0.2, generator: (i) => AcceleratedParticle(speed: Vector2.random() * 100, child: CircleParticle(radius: 2, paint: Paint()..color=Colors.white)))
            ));
            other.removeFromParent();
        }
    } else if (!isPlayerOwned && other is Player) {
      if (!other.isDead) {
        other.takeDamage(damage);
        removeFromParent();
      }
    }
  }
}
