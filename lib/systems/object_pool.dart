import 'dart:collection';

/// Generic Object Pool
///
/// Strategy: "remove-and-re-add"
/// - When a component is released it is removed from the game tree but
///   the Dart object is kept alive in this queue.
/// - When acquired again the same object is reset and re-added to the tree.
/// - onLoad() is guarded with [_poolInitialized] inside each component so
///   it only runs its setup once, even if Flame re-invokes it on re-add.
///
/// Usage:
/// ```dart
/// final bullet = pool.acquire();
/// bullet.resetForPool(...);
/// game.add(bullet);
/// // later:
/// pool.release(bullet);
/// bullet.removeFromParent();
/// ```
class ObjectPool<T> {
  final Queue<T> _available = Queue<T>();
  final T Function() _create;
  final int maxSize;

  ObjectPool({required T Function() create, this.maxSize = 60})
      : _create = create;

  /// Returns an object from the pool, or creates a new one if empty.
  T acquire() {
    if (_available.isNotEmpty) return _available.removeFirst();
    return _create();
  }

  /// Returns [obj] to the pool for future reuse.
  /// Call [removeFromParent()] on the component separately.
  void release(T obj) {
    if (_available.length < maxSize) {
      _available.addLast(obj);
    }
    // If pool is full the object will be GC'd — this is acceptable.
  }

  int get pooledCount => _available.length;

  /// Pre-warms the pool by creating [count] objects and storing them.
  void prewarm(int count) {
    for (int i = 0; i < count; i++) {
      _available.addLast(_create());
    }
  }
}
