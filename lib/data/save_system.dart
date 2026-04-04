import 'package:shared_preferences/shared_preferences.dart';

class SaveSystem {
  static late SharedPreferences _prefs;
  
  static int currentCrystals = 0;
  static int upgradedMaxHealth = 0;
  static int upgradedBaseDamage = 0;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    currentCrystals = _prefs.getInt('karmaCrystals') ?? 0;
    upgradedMaxHealth = _prefs.getInt('upgradedMaxHealth') ?? 0;
    upgradedBaseDamage = _prefs.getInt('upgradedBaseDamage') ?? 0;
  }

  static Future<void> addCrystals(int amount) async {
    currentCrystals += amount;
    await _prefs.setInt('karmaCrystals', currentCrystals);
  }

  static Future<bool> spendCrystals(int amount) async {
    if (currentCrystals >= amount) {
      currentCrystals -= amount;
      await _prefs.setInt('karmaCrystals', currentCrystals);
      return true;
    }
    return false;
  }

  static Future<void> upgradeHealth() async {
    upgradedMaxHealth += 10;
    await _prefs.setInt('upgradedMaxHealth', upgradedMaxHealth);
  }

  static Future<void> upgradeDamage() async {
    upgradedBaseDamage += 1;
    await _prefs.setInt('upgradedBaseDamage', upgradedBaseDamage);
  }
}
