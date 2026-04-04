import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import 'bullet.dart';
import 'pickup.dart';
import 'damage_text.dart';
import '../systems/audio_system.dart';

enum BossPhase { phase1, phase2, phase3 }

class Boss extends PositionComponent with HasGameRef<CyberMonkGame>, CollisionCallbacks {
  double maxHealth;
  double health;
  bool isDead = false;
  BossPhase phase = BossPhase.phase1;

  double fireTimer = 0;
  double spiralAngle = 0;
  double moveTimer = 0;
  double moveDir = 1;
  double timeAlive = 0;
  double hitFlashTimer = 0;

  final Random rng = Random();
  final int waveNumber;

  Boss({required super.position, required this.waveNumber})
      : maxHealth = 500 + waveNumber * 200,
        health = 500 + waveNumber * 200,
        super(
          size: Vector2(80, 80),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  BossPhase _calculatePhase() {
    double pct = health / maxHealth;
    if (pct > 0.6) return BossPhase.phase1;
    if (pct > 0.3) return BossPhase.phase2;
    return BossPhase.phase3;
  }

  Color _getPhaseColor() {
    switch (phase) {
      case BossPhase.phase1: return Colors.redAccent;
      case BossPhase.phase2: return Colors.orangeAccent;
      case BossPhase.phase3: return Colors.purpleAccent;
    }
  }

  @override
  void render(Canvas canvas) {
    if (hitFlashTimer > 0) {
      canvas.drawRect(size.toRect(), Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 20));
      return;
    }

    Color col = _getPhaseColor();

    // Outer pulsing aura
    Paint aura = Paint()
      ..color = col.withOpacity(0.2 + 0.1 * sin(timeAlive * 4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(size.toRect().inflate(10), aura);

    // Boss shape: layered hexagon
    Path hex = _hexPath(size.x / 2, size.y / 2, size.x / 2);
    canvas.drawPath(hex, Paint()..color = Colors.black);
    canvas.drawPath(hex, Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12));
    canvas.drawPath(hex, Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Inner core symbol
    Paint corePaint = Paint()
      ..color = col.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, corePaint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, Paint()..color = Colors.white);

    // Health bar
    double hpPct = health / maxHealth;
    Paint bgBar = Paint()..color = Colors.white24;
    Paint fgBar = Paint()..color = col;
    Rect barBg = Rect.fromLTWH(0, -15, size.x, 6);
    Rect barFg = Rect.fromLTWH(0, -15, size.x * hpPct, 6);
    canvas.drawRect(barBg, bgBar);
    canvas.drawRect(barFg, fgBar);
  }

  Path _hexPath(double cx, double cy, double r) {
    Path p = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (pi / 3) * i - pi / 6;
      double x = cx + r * cos(angle);
      double y = cy + r * sin(angle);
      if (i == 0) p.moveTo(x, y); else p.lineTo(x, y);
    }
    p.close();
    return p;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    timeAlive += dt;
    phase = _calculatePhase();

    if (hitFlashTimer > 0) hitFlashTimer -= dt;

    // Boss side-to-side movement
    moveTimer += dt;
    position.x += moveDir * 80 * dt;
    if (position.x <= size.x / 2 || position.x >= gameRef.size.x - size.x / 2) {
      moveDir *= -1;
    }
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);

    // Slow descent to center-top
    if (position.y < 150) {
      position.y += 40 * dt;
    }

    fireTimer += dt;
    _attack(dt);
  }

  void _attack(double dt) {
    switch (phase) {
      case BossPhase.phase1:
        // Spread spiral shots every 0.3s
        if (fireTimer >= 0.3) {
          fireTimer = 0;
          _spiralShot(3);
        }
        break;

      case BossPhase.phase2:
        // Faster spiral + aimed shots every 0.2s
        if (fireTimer >= 0.2) {
          fireTimer = 0;
          _spiralShot(5);
          _aimedShot();
        }
        break;

      case BossPhase.phase3:
        // Rage mode: dense spiral + burst + mines
        if (fireTimer >= 0.12) {
          fireTimer = 0;
          _spiralShot(8);
          _aimedShot();
          if (rng.nextDouble() > 0.7) _burstShot();
        }
        break;
    }
  }

  void _spiralShot(int arms) {
    spiralAngle += 0.15;
    for (int i = 0; i < arms; i++) {
      double angle = spiralAngle + (2 * pi / arms) * i;
      Vector2 vel = Vector2(cos(angle), sin(angle)) * 250;
      gameRef.add(Bullet(
        position: position.clone() + Vector2(size.x / 2, size.y / 2),
        velocity: vel,
        damage: _phaseDamage(),
        isPlayerOwned: false,
        paintColor: _phaseColor(),
      ));
    }
  }

  void _aimedShot() {
    // Shot aimed directly at player
    Vector2 playerPos = gameRef.player.position;
    Vector2 dir = (playerPos - (position + Vector2(size.x / 2, size.y / 2))).normalized();
    gameRef.add(Bullet(
      position: position.clone() + Vector2(size.x / 2, size.y / 2),
      velocity: dir * 350,
      damage: _phaseDamage() * 1.5,
      isPlayerOwned: false,
      paintColor: Colors.white,
    ));
  }

  void _burstShot() {
    // 360° burst of 12 bullets
    for (int i = 0; i < 12; i++) {
      double angle = (2 * pi / 12) * i;
      Vector2 vel = Vector2(cos(angle), sin(angle)) * 200;
      gameRef.add(Bullet(
        position: position.clone() + Vector2(size.x / 2, size.y / 2),
        velocity: vel,
        damage: _phaseDamage(),
        isPlayerOwned: false,
        paintColor: Colors.purpleAccent,
      ));
    }
  }

  double _phaseDamage() {
    switch (phase) {
      case BossPhase.phase1: return 8;
      case BossPhase.phase2: return 12;
      case BossPhase.phase3: return 18;
    }
  }

  Color _phaseColor() {
    switch (phase) {
      case BossPhase.phase1: return Colors.redAccent;
      case BossPhase.phase2: return Colors.orangeAccent;
      case BossPhase.phase3: return Colors.purpleAccent;
    }
  }

  void takeDamage(double amount) {
    health -= amount;
    hitFlashTimer = 0.08;
    AudioSystem.playSFX('hit.wav', volume: 0.6);

    // Spawn damage number
    if (amount >= 1.0) {
      gameRef.add(DamageText(text: amount.toInt().toString(), position: position.clone(), isCritical: true));
    }

    if (health <= 0 && !isDead) {
      die();
    }
  }

  void die() {
    isDead = true;
    AudioSystem.playSFX('explode.wav', volume: 1.0);
    
    // Screen shake
    gameRef.camera.viewfinder.add(
      MoveByEffect(
        Vector2(10, 10),
        RepeatedEffectController(SequenceEffectController([
          LinearEffectController(0.05),
          ReverseLinearEffectController(0.05),
        ]), 5),
      )
    );

    // Massive death explosion
    gameRef.add(ParticleSystemComponent(
      position: position.clone() + Vector2(size.x / 2, size.y / 2),
      particle: Particle.generate(
        count: 80,
        lifespan: 1.0,
        generator: (i) => AcceleratedParticle(
          speed: Vector2((rng.nextDouble() - 0.5) * 1000, (rng.nextDouble() - 0.5) * 1000),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              Color c = [Colors.orangeAccent, Colors.redAccent, Colors.purpleAccent, Colors.white][rng.nextInt(4)];
              canvas.drawCircle(Offset.zero, 10 * (1 - particle.progress),
                  Paint()..color = c.withOpacity(1 - particle.progress)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6));
            },
          ),
        ),
      ),
    ));

    // Drop a huge EXP reward
    for (int i = 0; i < 5; i++) {
      gameRef.add(Pickup(
        position: position.clone() + Vector2(rng.nextDouble() * 60 - 30, rng.nextDouble() * 60 - 30),
        type: PickupType.exp,
        expValue: 60,
      ));
    }
    // Also drop karma orbs
    gameRef.add(Pickup(position: position.clone(), type: PickupType.lightKarma));
    gameRef.add(Pickup(position: position.clone() + Vector2(20, 0), type: PickupType.darkKarma));

    // Notify game that boss is dead
    gameRef.onBossDead();
    removeFromParent();
  }
}
