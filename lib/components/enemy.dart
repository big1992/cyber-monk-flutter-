import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import 'bullet.dart';
import 'pickup.dart';
import 'player.dart';

enum EnemyType { scrapper, ninja, tank }

class Enemy extends PositionComponent with HasGameRef<CyberMonkGame>, CollisionCallbacks {
  final EnemyType type;
  double health = 10;
  bool isDead = false;
  double fireTimer = 0;
  late double maxHealth;
  late double speed;
  double timeAlive = 0;
  
  final Random rng = Random();

  // Status Effects
  double dotDamagePerSecond = 0;
  double slowMultiplier = 1.0;
  double frozenTimer = 0;
  double burnTimer = 0;
  double hitFlashTimer = 0;

  Enemy({
    required super.position,
    required this.type,
    double waveMultiplier = 1.0,
  }) : super(
          size: Vector2(30, 30),
          anchor: Anchor.center,
        ) {
    _setupStats(waveMultiplier);
  }

  void _setupStats(double mult) {
    switch (type) {
      case EnemyType.scrapper:
        health = 10 * mult;
        speed = 100;
        break;
      case EnemyType.ninja:
        health = 25 * mult;
        speed = 150;
        size = Vector2(25, 25);
        break;
      case EnemyType.tank:
        health = 100 * mult;
        speed = 40;
        size = Vector2(50, 50);
        break;
    }
    maxHealth = health;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  Color _getBaseColor() {
      if (frozenTimer > 0) return Colors.lightBlueAccent;
      if (burnTimer > 0) return Colors.orangeAccent;
      if (type == EnemyType.ninja) return Colors.purpleAccent;
      if (type == EnemyType.tank) return Colors.orange;
      return Colors.redAccent;
  }

  @override
  void render(Canvas canvas) {
      if (hitFlashTimer > 0) {
          canvas.drawRect(size.toRect(), Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10));
          return;
      }

      Color baseCol = _getBaseColor();
      
      Paint neonGlow = Paint()
         ..color = baseCol
         ..style = PaintingStyle.stroke
         ..strokeWidth = 3
         ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
         
      Paint solidBody = Paint()..color = Colors.black;
      Paint brightEdge = Paint()..color = baseCol..style = PaintingStyle.stroke..strokeWidth = 2;

      Path p = Path();
      if (type == EnemyType.scrapper) {
        p.moveTo(0, 0); p.lineTo(size.x, 0); p.lineTo(size.x/2, size.y); p.close();
      } else if (type == EnemyType.ninja) {
        p.moveTo(size.x/2, 0); p.lineTo(size.x, size.y/2); p.lineTo(size.x/2, size.y); p.lineTo(0, size.y/2); p.close();
      } else if (type == EnemyType.tank) {
        p.moveTo(size.x * 0.25, 0); p.lineTo(size.x * 0.75, 0); p.lineTo(size.x, size.y / 2); p.lineTo(size.x * 0.75, size.y); p.lineTo(size.x * 0.25, size.y); p.lineTo(0, size.y / 2); p.close();
      }

      canvas.drawPath(p, solidBody);
      canvas.drawPath(p, neonGlow);
      canvas.drawPath(p, brightEdge);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    // Lotus Aura Slow
    double currentSlow = 1.0;
    if (gameRef.player.lotusAuraSlowPct > 0) {
        if (position.distanceToSquared(gameRef.player.position) < 40000) { // 200 units radius
            currentSlow -= gameRef.player.lotusAuraSlowPct;
        }
    }

    if (hitFlashTimer > 0) {
        hitFlashTimer -= dt;
    }
    if (frozenTimer > 0) {
        frozenTimer -= dt;
        currentSlow *= 0.5;
    } 
    if (burnTimer > 0) {
        burnTimer -= dt;
    }

    timeAlive += dt;

    // DoT 
    if (dotDamagePerSecond > 0) {
        takeDamage(dotDamagePerSecond * dt);
    }
    if (burnTimer > 0) {
        takeDamage(5.0 * dt);
    }

    if (currentSlow < 0.1) currentSlow = 0.1;

    // Movement logic
    switch (type) {
      case EnemyType.scrapper:
      case EnemyType.tank:
        position.y += speed * currentSlow * dt;
        break;
      case EnemyType.ninja:
        position.y += speed * currentSlow * dt;
        position.x += sin(timeAlive * 3) * 100 * currentSlow * dt; 
        break;
    }

    // Prevent going off screen horizontally
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);

    // Shooting logic
    fireTimer += dt;
    if (type == EnemyType.scrapper && fireTimer >= 1.5) {
      fireTimer = 0;
      gameRef.add(Bullet(
        position: position.clone() + Vector2(0, size.y / 2),
        velocity: Vector2(0, 300),
        damage: 10,
        isPlayerOwned: false,
        paintColor: Colors.deepOrange,
      ));
    } else if (type == EnemyType.tank && fireTimer >= 3.0) {
      fireTimer = 0;
      gameRef.add(Bullet(
        position: position.clone() + Vector2(0, size.y / 2),
        velocity: Vector2(0, 150),
        damage: 30,
        isPlayerOwned: false,
        paintColor: Colors.red,
      )..scale = Vector2.all(2));
    } else if (type == EnemyType.ninja && fireTimer >= 1.0) {
      fireTimer = 0;
      for (int i = -1; i <= 1; i++) {
        gameRef.add(Bullet(
          position: position.clone() + Vector2(0, size.y / 2),
          velocity: Vector2(i * 100, 300),
          damage: 5,
          isPlayerOwned: false,
          paintColor: Colors.purple,
        ));
      }
    }

    if (position.y > gameRef.size.y + 100) {
      removeFromParent();
    }
  }

  void takeDamage(double amount, {double dotPct = 0.0, bool isIce = false, bool isFire = false}) {
    health -= amount;
    hitFlashTimer = 0.1; // Flash white for 0.1s feeling
    
    if (dotPct > 0) {
        dotDamagePerSecond += 10 * dotPct; // Adds a stack
    }
    if (isIce) frozenTimer = 2.0;
    if (isFire) burnTimer = 2.0;

    if (health <= 0 && !isDead) { // Check !isDead to prevent double call
      die();
    }
  }

  void die() {
    isDead = true;
    
    // Corpse Explosion
    if (gameRef.player.corpseExplosionDmgPct > 0) {
        // Find other enemies
        double boomDmg = maxHealth * gameRef.player.corpseExplosionDmgPct;
        for (final enemy in gameRef.children.whereType<Enemy>()) {
            if (enemy != this && !enemy.isDead && enemy.position.distanceToSquared(position) < 22500) { // 150 radius
                enemy.takeDamage(boomDmg);
            }
        }
        // VFX (Particle Explosion)
        gameRef.add(ParticleSystemComponent(
            position: position.clone(),
            particle: Particle.generate(
                count: 40,
                lifespan: 0.6,
                generator: (i) => AcceleratedParticle(
                    speed: Vector2((rng.nextDouble() - 0.5) * 800, (rng.nextDouble() - 0.5) * 800),
                    child: ComputedParticle(
                        renderer: (canvas, particle) {
                            final p = Paint()..color = Colors.orangeAccent.withOpacity(1 - particle.progress)..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
                            canvas.drawCircle(Offset.zero, 8 * (1 - particle.progress), p);
                        }
                    )
                )
            )
        ));
    } else {
        // Standard Death Sparkles
        Color deathColor = _getBaseColor();
        gameRef.add(ParticleSystemComponent(
            position: position.clone(),
            particle: Particle.generate(
                count: 20,
                lifespan: 0.4,
                generator: (i) => AcceleratedParticle(
                    speed: Vector2((rng.nextDouble() - 0.5) * 400, (rng.nextDouble() - 0.5) * 400),
                    child: ComputedParticle(
                        renderer: (canvas, particle) {
                            final p = Paint()..color = deathColor.withOpacity(1 - particle.progress);
                            canvas.drawRect(Rect.fromLTWH(-2, -2, 4, 4), p);
                        }
                    )
                )
            )
        ));
    }

    gameRef.player.triggerLifeSteal();

    // Spawn drop — EXP weighted by enemy type
    double expReward = type == EnemyType.tank ? 30 : type == EnemyType.ninja ? 20 : 15;
    double dropChance = rng.nextDouble();
    if (dropChance < 0.25) {
      gameRef.add(Pickup(position: position.clone(), type: PickupType.lightKarma));
    } else if (dropChance < 0.5) {
      gameRef.add(Pickup(position: position.clone(), type: PickupType.darkKarma));
    } else {
      // Always drop EXP with type-based value
      gameRef.add(Pickup(position: position.clone(), type: PickupType.exp, expValue: expReward));
    }

    removeFromParent();
  }
}
