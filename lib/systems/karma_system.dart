import 'package:flutter/foundation.dart';

class KarmaSystem extends ChangeNotifier {
  double _karma = 0; // -100 to 100
  double _exp = 0;
  double _expToNextLevel = 30; // Was 100 - much more achievable
  int _level = 1;

  int _pendingLevelUps = 0;
  int get pendingLevelUps => _pendingLevelUps;

  double get karma => _karma;
  double get exp => _exp;
  double get expToNextLevel => _expToNextLevel;
  int get level => _level;

  void addKarma(double amount) {
    _karma += amount;
    if (_karma > 100) _karma = 100;
    if (_karma < -100) _karma = -100;
    notifyListeners();
  }

  void addExp(double amount) {
    _exp += amount;
    while (_exp >= _expToNextLevel) {
      _exp -= _expToNextLevel;
      _level++;
      _pendingLevelUps++;
      _expToNextLevel *= 1.3;
    }
    notifyListeners();
  }

  void consumeLevelUp() {
    if (_pendingLevelUps > 0) {
      _pendingLevelUps--;
      notifyListeners();
    }
  }

  void reset() {
    _karma = 0;
    _exp = 0;
    _expToNextLevel = 30;
    _level = 1;
    notifyListeners();
  }
}
