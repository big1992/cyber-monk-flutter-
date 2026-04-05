import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import '../data/skills.dart';
import '../systems/audio_system.dart';

class Player extends PositionComponent with HasGameRef<CyberMonkGame>, CollisionCallbacks {
  double maxHealth = 100;
  double health = 100;
  double baseDamage = 10;
  bool isDead = false;

  double ultimateCharge = 0;
  double maxUltimateCharge = 100;

  double fireTimer = 0;
  // Stats
  double baseFireRateModifier = 0.0;
  double baseDamageModifier = 0.0;
  double get baseFireRate => 0.2 * (1.0 - baseFireRateModifier);
  double speedMultiplier = 1.0;
  double expMultiplier = 1.0;

  // Tracking
  List<SkillData> acquiredSkills = [];

  // New Skill Modifiers ---------------------
  
  // Defense / Sustain (Light)
  int nirvanaShieldCharges = 0;
  double nirvanaShieldTimer = 0;
  double nirvanaShieldCooldown = 5.0;
  
  double lotusAuraSlowPct = 0.0; // Slows enemies touching aura (not bullets for simplicity in MVP)
  
  double hpRegenPerSec = 0.0;
  double etherealStepInvulnTime = 0.0; // When taking damage, become invulnerable for this long
  double currentInvulnTimer = 0.0;

  double reflectivePalmDmgPct = 0.0; // Bounces bullets back at X damage
  
  int cleansingWaveCounter = 0;
  int cleansingWaveRequirement = 0; // 0 means disabled
  
  bool hasGuardianSpirit = false;
  double guardianSpiritAngle = 0.0;

  double standingStillTimer = 0.0;
  bool asceticFocusActive = false; // +200% fire rate when active

  // Damage / Risk (Dark)
  int demonBladePierces = 0;
  int shadowCloneCount = 0;
  double corpseExplosionDmgPct = 0.0; 
  double vengefulSpiritThreshold = 0.0; // 0.0 to 1.0
  int homingSkullsPerNShots = 0; 
  int skullCounter = 0;
  double dashPhaseCostPct = 0.0; // Costs X% HP to dash (leave trail, will skip trail for MVP)
  double cursedMarkDotPct = 0.0; // Stack dot on enemy
  double lifestealChance = 0.0;
  bool obliterationBeamActive = false; // Ultimate (simplified for MVP as a generic wide beam occasionally)
  
  // Balance
  int extraProjectiles = 0;
  int extraRicochets = 0;
  bool elementalSwapActive = false;
  double elementalSwapTimer = 0;
  bool isCurrentlyFire = true;
  bool hasDroneCompanion = false;

  // ----------------------------------------

  Player({required super.position})
      : super(
          size: Vector2(30, 40),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Draw Lotus Aura under player
    if (lotusAuraSlowPct > 0) {
        final auraColor = Colors.lightBlueAccent.withOpacity(0.1);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), 200, Paint()..color = auraColor);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), 200, Paint()..color = Colors.lightBlue.withOpacity(0.3)..style = PaintingStyle.stroke);
    }

    // Draw Nirvana Shield
    if (nirvanaShieldCharges > 0 && currentInvulnTimer <= 0) {
      final shieldPaint = Paint()
        ..color = Colors.yellowAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 35, shieldPaint);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 35, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // Cyber Monk Base Body (Diamond Path)
    Path path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y / 2)
      ..lineTo(size.x / 2, size.y)
      ..lineTo(0, size.y / 2)
      ..close();

    Color baseColor = currentInvulnTimer > 0 ? Colors.white54 : Colors.cyanAccent;
    
    // Outer intense glow
    canvas.drawPath(path, Paint()
      ..color = baseColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    // Core solid body
    canvas.drawPath(path, Paint()..color = Colors.white);

    // Draw Guardian Drone
    if (hasGuardianSpirit) {
        guardianSpiritAngle += 0.05;
        double dx = size.x / 2 + 40 * cos(guardianSpiritAngle);
        double dy = size.y / 2 + 40 * sin(guardianSpiritAngle);
        
        final dronePaint = Paint()
            ..color = Colors.greenAccent
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);
        canvas.drawCircle(Offset(dx, dy), 6, dronePaint);
        canvas.drawCircle(Offset(dx, dy), 2, Paint()..color = Colors.white);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    // HP Regen
    if (hpRegenPerSec > 0 && health < maxHealth) {
      health += hpRegenPerSec * dt;
      if (health > maxHealth) health = maxHealth;
    }

    // Invulnerability
    if (currentInvulnTimer > 0) {
      currentInvulnTimer -= dt;
    }

    // Nirvana Shield Replenish
    if (nirvanaShieldCooldown > 0 && nirvanaShieldCharges == 0) {
      nirvanaShieldTimer += dt;
      if (nirvanaShieldTimer >= nirvanaShieldCooldown) {
        nirvanaShieldCharges = 1;
        nirvanaShieldTimer = 0;
      }
    }

    // Elemental Swap
    if (elementalSwapActive) {
      elementalSwapTimer += dt;
      if (elementalSwapTimer >= 2.0) {
        isCurrentlyFire = !isCurrentlyFire;
        elementalSwapTimer = 0;
      }
    }

    // Ascetic Focus
    // We check if position changed in the main game loop. 
    // If not, increase standingStillTimer.
    // For MVP, if standingStillTimer > 1s, trigger buff.
    if (standingStillTimer > 1.0 && !asceticFocusActive) {
      asceticFocusActive = true;
    } else if (standingStillTimer == 0 && asceticFocusActive) {
      asceticFocusActive = false;
    }

    // Fire logic
    double karmaFireRateBonus = (gameRef.karmaSystem.karma > 0) 
        ? gameRef.karmaSystem.karma * 0.003 // Max 30%
        : 0;
        
    double currentFireRate = baseFireRate * (1.0 - karmaFireRateBonus);
    if (asceticFocusActive) currentFireRate /= 3.0; // 200% faster (1/3 delay)
    if (currentFireRate < 0.05) currentFireRate = 0.05; // Prevent dividing by 0 or infinite bullets

    fireTimer += dt;
    if (fireTimer >= currentFireRate) {
      fireTimer = 0;
      shoot();
    }
  }

  void shoot() {
    double currentBaseDamage = baseDamage * (1.0 + baseDamageModifier);
    if (currentBaseDamage < 1.0) currentBaseDamage = 1.0; // Clamp min damage to prevent negative/0 damage

    double karmaDmgBonus = (gameRef.karmaSystem.karma < 0) 
        ? gameRef.karmaSystem.karma.abs() * 0.005
        : 0;
        
    double currentDamage = currentBaseDamage * (1.0 + karmaDmgBonus);
    if (vengefulSpiritThreshold > 0 && (health / maxHealth) < vengefulSpiritThreshold) {
      currentDamage *= 2.0; // +100% damage if under threshold
    }

    Color bulletColor = Colors.cyan;
    if (elementalSwapActive) {
        bulletColor = isCurrentlyFire ? Colors.orange : Colors.lightBlueAccent;
    }

    bool isHomingMode = false;
    if (homingSkullsPerNShots > 0) {
      skullCounter++;
      if (skullCounter >= homingSkullsPerNShots) {
        skullCounter = 0;
        isHomingMode = true;
        bulletColor = Colors.deepPurple;
      }
    }

    bool isCleansing = false;
    if (cleansingWaveRequirement > 0) {
        cleansingWaveCounter++;
        if (cleansingWaveCounter >= cleansingWaveRequirement) {
            cleansingWaveCounter = 0;
            isCleansing = true;
            bulletColor = Colors.white;
        }
    }

    void spawnPlayerBullet(Vector2 pos, Vector2 vel, double dmg, bool homing, bool cleanse) {
        gameRef.poolManager.spawnBullet(
            gameRef,
            position: pos,
            velocity: vel,
            damage: dmg,
            isPlayerOwned: true,
            paintColor: bulletColor,
            piercesRemaining: demonBladePierces + (cleanse ? 10 : 0),
            bouncesRemaining: extraRicochets,
            isHoming: homing,
            isCleansing: cleanse,
            dotPct: cursedMarkDotPct,
            isIce: elementalSwapActive && !isCurrentlyFire,
            isFire: elementalSwapActive && isCurrentlyFire,
        );
    }

    // Main shot
    AudioSystem.playSFX('shoot.wav', volume: 0.3, throttleMs: 100);
    spawnPlayerBullet(
      position.clone() - Vector2(0, size.y / 2),
      Vector2(0, -500),
      currentDamage,
      isHomingMode,
      isCleansing,
    );

    // Shadows
    for (int i = 1; i <= shadowCloneCount; i++) {
        double offset = (i % 2 == 1 ? -1 : 1) * 20.0 * ((i + 1) ~/ 2);
        spawnPlayerBullet(
          position.clone() + Vector2(offset, -size.y / 2),
          Vector2(0, -500),
          currentDamage * 0.3,
          isHomingMode,
          false,
        );
    }

    // Twin Dragons
    for (int i = 1; i <= extraProjectiles; i++) {
      spawnPlayerBullet(
        position.clone() - Vector2(0, size.y / 2),
        Vector2(-100.0 * i, -500),
        currentDamage * 0.8,
        false,
        false,
      );
      spawnPlayerBullet(
        position.clone() - Vector2(0, size.y / 2),
        Vector2(100.0 * i, -500),
        currentDamage * 0.8,
        false,
        false,
      );
    }
  }

  void takeDamage(double amount) {
    if (currentInvulnTimer > 0) return; // Invulnerable

    if (nirvanaShieldCharges > 0) {
       nirvanaShieldCharges--;
       // Trigger ethereal step invuln and reflect
       if (etherealStepInvulnTime > 0) currentInvulnTimer = etherealStepInvulnTime;
       
       if (reflectivePalmDmgPct > 0) {
           gameRef.poolManager.spawnBullet(
            gameRef,
            position: position.clone(),
            velocity: Vector2(0, -300),
            damage: 10 * reflectivePalmDmgPct,
            isPlayerOwned: true,
            paintColor: Colors.yellow,
            isHoming: true,
          );
       }
       return;
    }

    double dmgPenalty = (gameRef.karmaSystem.karma < 0)
        ? gameRef.karmaSystem.karma.abs() * 0.0025
        : 0;
    dmgPenalty += 0.1 * shadowCloneCount; // Takes 10% more damage per clone

    double finalDmg = amount * (1.0 + dmgPenalty);
    if (gameRef.karmaSystem.karma > 0) {
       finalDmg *= (1.0 - (gameRef.karmaSystem.karma * 0.002));
    }
    
    health -= finalDmg;
    
    if (etherealStepInvulnTime > 0) {
        currentInvulnTimer = etherealStepInvulnTime;
    }

    if (health <= 0) {
      health = 0;
      isDead = true;
    }
  }

  void triggerLifeSteal() {
      if (lifestealChance > 0) {
          // Lifesteal 1% chance implemented downstream (enemy death)
      }
  }

  void reset(Vector2 newPos) {
    position = newPos;
    health = maxHealth;
    isDead = false;
    fireTimer = 0;
    _resetSkills();
  }

  void _resetSkills() {
    baseFireRateModifier = 0.0;
    baseDamageModifier = 0.0;
    speedMultiplier = 1.0;
    expMultiplier = 1.0;
    
    nirvanaShieldCharges = 0;
    nirvanaShieldTimer = 0;
    lotusAuraSlowPct = 0.0;
    hpRegenPerSec = 0.0;
    etherealStepInvulnTime = 0.0;
    currentInvulnTimer = 0.0;
    reflectivePalmDmgPct = 0.0;
    cleansingWaveCounter = 0;
    cleansingWaveRequirement = 0;
    hasGuardianSpirit = false;
    standingStillTimer = 0.0;
    asceticFocusActive = false;

    demonBladePierces = 0;
    shadowCloneCount = 0;
    corpseExplosionDmgPct = 0.0;
    vengefulSpiritThreshold = 0.0;
    homingSkullsPerNShots = 0;
    skullCounter = 0;
    dashPhaseCostPct = 0.0;
    cursedMarkDotPct = 0.0;
    lifestealChance = 0.0;
    obliterationBeamActive = false;

    extraProjectiles = 0;
    extraRicochets = 0;
    elementalSwapActive = false;
    elementalSwapTimer = 0;
    isCurrentlyFire = true;
    hasDroneCompanion = false;
    acquiredSkills.clear();
  }
}
