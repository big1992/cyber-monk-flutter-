import 'package:flutter/material.dart';
import '../components/player.dart';

enum SkillAlignment { light, dark, balance }

class SkillData {
  final String name;
  final String description;
  final SkillAlignment alignment;
  final IconData icon; // Placeholder for UI
  final void Function(Player) applyEffect;

  const SkillData({
    required this.name,
    required this.description,
    required this.alignment,
    required this.icon,
    required this.applyEffect,
  });
}

final List<SkillData> allSkills = [
  // ================= LIGHT SKILLS =================
  SkillData(
    name: 'Nirvana Shield',
    description: 'Periodic shield blocking 1 hit. (Light Karma +10)',
    alignment: SkillAlignment.light,
    icon: Icons.shield,
    applyEffect: (player) {
      if (player.nirvanaShieldCooldown == 0) player.nirvanaShieldCooldown = 5.0; // Base
      else player.nirvanaShieldCooldown = (player.nirvanaShieldCooldown - 0.5).clamp(1.0, 5.0);
      player.nirvanaShieldCharges = 1;
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Lotus Aura',
    description: 'Aura slows nearby enemy bullets/moves by 20%.',
    alignment: SkillAlignment.light,
    icon: Icons.spa,
    applyEffect: (player) {
      player.lotusAuraSlowPct += 0.2;
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Mend Wounds',
    description: 'Heals 1 HP every 5 seconds.',
    alignment: SkillAlignment.light,
    icon: Icons.healing,
    applyEffect: (player) {
      player.hpRegenPerSec += 0.2; // 1 every 5s
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Ethereal Step',
    description: 'Invulnerable for 1s after taking damage.',
    alignment: SkillAlignment.light,
    icon: Icons.directions_walk,
    applyEffect: (player) {
      player.etherealStepInvulnTime += 0.5; // Base 0 to 0.5, 1.0...
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Reflective Palm',
    description: 'Shield absorbs fire a homing blast of light.',
    alignment: SkillAlignment.light,
    icon: Icons.back_hand,
    applyEffect: (player) {
      player.reflectivePalmDmgPct += 2.0; // 200% base damage reflection
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Cleansing Wave',
    description: 'Every 8th shot clears enemy bullets and pierces.',
    alignment: SkillAlignment.light,
    icon: Icons.waves,
    applyEffect: (player) {
      if (player.cleansingWaveRequirement == 0) player.cleansingWaveRequirement = 10;
      else player.cleansingWaveRequirement = (player.cleansingWaveRequirement - 2).clamp(4, 10);
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Vitality Mantra',
    description: 'Increases Max HP by 20%.',
    alignment: SkillAlignment.light,
    icon: Icons.favorite,
    applyEffect: (player) {
      player.maxHealth *= 1.2;
      player.health += player.maxHealth * 0.2;
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Guardian Spirit',
    description: 'Summons an orbital drone (Passive +HP/Armor).',
    alignment: SkillAlignment.light,
    icon: Icons.track_changes,
    applyEffect: (player) {
      player.hasGuardianSpirit = true;
      player.maxHealth += 50; 
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Ascetic Focus',
    description: 'Standing still for 1s grants massive fire rate.',
    alignment: SkillAlignment.light,
    icon: Icons.self_improvement,
    applyEffect: (player) {
      // Activated in Player update loop
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),
  SkillData(
    name: 'Sola Blessing',
    description: 'Restores 30% HP instantly and +Max HP.',
    alignment: SkillAlignment.light,
    icon: Icons.flare,
    applyEffect: (player) {
      player.maxHealth += 10;
      player.health = (player.health + (player.maxHealth * 0.3)).clamp(0, player.maxHealth);
      player.gameRef.karmaSystem.addKarma(10);
    },
  ),

  // ================= DARK SKILLS =================
  SkillData(
    name: 'Demon Blade',
    description: 'Attacks pierce through 1 additional enemy. (Dark Karma -10)',
    alignment: SkillAlignment.dark,
    icon: Icons.hardware,
    applyEffect: (player) {
      player.demonBladePierces += 1;
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Blood Pact',
    description: 'Sacrifice 20% Health for +30% Base Damage.',
    alignment: SkillAlignment.dark,
    icon: Icons.bloodtype,
    applyEffect: (player) {
      if (player.health > player.maxHealth * 0.25) {
        player.health -= player.maxHealth * 0.2;
      }
      player.baseDamageModifier += 0.3;
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Shadow Clone',
    description: 'Fires an extra stream of attacks at 30% damage.',
    alignment: SkillAlignment.dark,
    icon: Icons.people_outline,
    applyEffect: (player) {
      player.hasShadowClone = true;
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Corpse Explosion',
    description: 'Enemies explode on death for AoE damage.',
    alignment: SkillAlignment.dark,
    icon: Icons.coronavirus,
    applyEffect: (player) {
      player.corpseExplosionDmgPct += 0.5;
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Vengeful Spirit',
    description: 'Deal +100% damage when below 30% HP.',
    alignment: SkillAlignment.dark,
    icon: Icons.mood_bad,
    applyEffect: (player) {
      player.vengefulSpiritThreshold = 0.3; // 30% HP
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Homing Skulls',
    description: 'Every 5th shot fires homing dark magic.',
    alignment: SkillAlignment.dark,
    icon: Icons.rocket,
    applyEffect: (player) {
      if (player.homingSkullsPerNShots == 0) player.homingSkullsPerNShots = 5;
      else player.homingSkullsPerNShots = (player.homingSkullsPerNShots - 1).clamp(2, 5);
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Void Dash',
    description: 'Increases Fire Rate greatly but sacrifices HP max.',
    alignment: SkillAlignment.dark,
    icon: Icons.flash_on,
    applyEffect: (player) {
      player.baseFireRateModifier += 0.2; // 20% faster
      player.maxHealth *= 0.9;
      if (player.health > player.maxHealth) player.health = player.maxHealth;
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Cursed Mark',
    description: 'Your shots apply a stacking damaging poison.',
    alignment: SkillAlignment.dark,
    icon: Icons.blur_on,
    applyEffect: (player) {
      player.cursedMarkDotPct += 0.1; // 10%
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Life Steal',
    description: 'Heal slightly on kill, take +10% more damage.',
    alignment: SkillAlignment.dark,
    icon: Icons.water_drop,
    applyEffect: (player) {
      player.lifestealChance += 0.05; // 5% chance implemented via triggerLifeSteal manually (we'll just heal a bit directly)
      player.hpRegenPerSec += 0.5; // MVP simplification for lifesteal
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),
  SkillData(
    name: 'Obliteration Power',
    description: 'Massive Raw Damage multiplier +100%.',
    alignment: SkillAlignment.dark,
    icon: Icons.whatshot,
    applyEffect: (player) {
      player.baseDamageModifier += 1.0; 
      player.speedMultiplier *= 0.8; // Slows movement
      player.gameRef.karmaSystem.addKarma(-10);
    },
  ),

  // ================= BALANCE SKILLS =================
  SkillData(
    name: 'Twin Dragons',
    description: 'Fires extra diagonal projectiles.',
    alignment: SkillAlignment.balance,
    icon: Icons.call_split,
    applyEffect: (player) {
      player.extraProjectiles += 1;
    },
  ),
  SkillData(
    name: 'Swiftness Rune',
    description: 'Increases movement speed by 20%.',
    alignment: SkillAlignment.balance,
    icon: Icons.speed,
    applyEffect: (player) {
      player.speedMultiplier += 0.2;
    },
  ),
  SkillData(
    name: 'Magnetic Field',
    description: 'Increases pick up range.',
    alignment: SkillAlignment.balance,
    icon: Icons.all_out,
    applyEffect: (player) {
      player.expMultiplier += 0.5; // Stand-in for magnetic pull range
    },
  ),
  SkillData(
    name: 'Overclock',
    description: 'Reduces skill cooldowns.',
    alignment: SkillAlignment.balance,
    icon: Icons.update,
    applyEffect: (player) {
      player.nirvanaShieldCooldown *= 0.8;
      player.baseFireRateModifier += 0.1;
    },
  ),
  SkillData(
    name: 'Karma Conversion',
    description: 'Max HP +50, Damage +20%.',
    alignment: SkillAlignment.balance,
    icon: Icons.change_circle,
    applyEffect: (player) {
      player.maxHealth += 50;
      player.health += 50;
      player.baseDamageModifier += 0.2;
    },
  ),
  SkillData(
    name: 'Ricochet',
    description: 'Shots bounce off screen edges.',
    alignment: SkillAlignment.balance,
    icon: Icons.sync,
    applyEffect: (player) {
      player.extraRicochets += 1;
    },
  ),
  SkillData(
    name: 'Elemental Swap',
    description: 'Shots alternate between Fire(Burn) and Ice(Slow).',
    alignment: SkillAlignment.balance,
    icon: Icons.ac_unit,
    applyEffect: (player) {
      player.elementalSwapActive = true;
    },
  ),
  SkillData(
    name: 'Enlightened Mind',
    description: 'Gain 25% more EXP.',
    alignment: SkillAlignment.balance,
    icon: Icons.psychology,
    applyEffect: (player) {
      player.expMultiplier += 0.25;
    },
  ),
  SkillData(
    name: 'Precision',
    description: 'Damage +15%, Fire Rate +15%.',
    alignment: SkillAlignment.balance,
    icon: Icons.gps_fixed,
    applyEffect: (player) {
      player.baseDamageModifier += 0.15;
      player.baseFireRateModifier += 0.15;
    },
  ),
  SkillData(
    name: 'Multishot',
    description: 'Another Twin Dragon + Base Damage down.',
    alignment: SkillAlignment.balance,
    icon: Icons.storm,
    applyEffect: (player) {
      player.extraProjectiles += 1;
      player.baseDamageModifier -= 0.1;
    },
  ),
];
