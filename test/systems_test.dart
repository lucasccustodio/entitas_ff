import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

class _MoveSystem extends EntityManagerSystem
    implements InitSystem, ExecuteSystem, CleanupSystem {
  EntityGroup _movable;
  @override
  init() {
    _movable = entityManager.group(all: [Position, Velocity]);
  }

  @override
  execute() {
    for (var e in _movable.entities) {
      var posX = e.get<Position>().value.x + e.get<Velocity>().value.x;
      var posY = e.get<Position>().value.y + e.get<Velocity>().value.y;
      e.set(Position(posX, posY));
    }
  }

  @override
  cleanup() {
    for (var e in _movable.entities) {
      var pos = e.get<Position>();
      if (pos.value.x > 100 || pos.value.y > 100) {
        e.destroy();
      }
    }
  }
}

class _InteractiveMoveSystem extends ReactiveSystem implements CleanupSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [Selected, Position]);

  @override
  void executeWith(List<ObservableEntity> entities) {
    for (var e in entities) {
      var posX = e.get<Position>().value.x + 1;
      var posY = e.get<Position>().value.y + 1;
      e.set(Position(posX, posY));
    }
  }

  @override
  cleanup() {
    for (var e in entityManager.group(all: [Selected]).entities) {
      e.remove<Selected>();
    }
  }
}

class _TriggeredMoveSystem extends TriggeredSystem implements InitSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [Selected]);

  EntityGroup _movable;
  @override
  init() {
    _movable = entityManager.group(all: [Position]);
  }

  @override
  executeOnChange() {
    for (var e in _movable.entities) {
      var posX = e.get<Position>().value.x + 1;
      var posY = e.get<Position>().value.y + 1;
      e.set(Position(posX, posY));
    }
  }
}

void main() {
  test('Move System', () {
    var em = EntityManager();
    var root = RootSystem(entityManager: em, systems: [_MoveSystem()]);

    var e1 = em.createEntity()..set(Position(0, 0))..set(Velocity(1, 0));

    var e2 = em.createEntity()
      ..set(Name('e2'))
      ..set(Position(0, 0))
      ..set(Velocity(0, 1));

    root.init();

    for (var i = 0; i < 100; i++) {
      root.execute();
      root.cleanup();
    }

    expect(e1.isAlive, true);
    expect(e2.isAlive, true);

    expect(e1.get<Position>().value.x, 100);
    expect(e1.get<Position>().value.y, 0);

    expect(e2.get<Position>().value.x, 0);
    expect(e2.get<Position>().value.y, 100);

    root.execute();
    root.cleanup();

    expect(e1.isAlive, false);
    expect(e2.isAlive, false);
  });

  test('Interactive Move System', () {
    var em = EntityManager();
    var root = ReactiveRootSystem(
        entityManager: em, systems: [_InteractiveMoveSystem()]);

    var e1 = em.createEntity()..set(Position(0, 0));

    var e2 = em.createEntity()..set(Position(0, 0));

    root.init();

    for (var i = 0; i < 100; i++) {
      root.execute();
      root.cleanup();
    }

    expect(e1.isAlive, true);
    expect(e2.isAlive, true);

    expect(e1.get<Position>().value.x, 0);
    expect(e1.get<Position>().value.y, 0);

    expect(e2.get<Position>().value.x, 0);
    expect(e2.get<Position>().value.y, 0);

    e1 += Selected();

    root.execute();
    root.cleanup();

    expect(e1.get<Position>().value.x, 1);
    expect(e1.get<Position>().value.y, 1);

    expect(e2.get<Position>().value.x, 0);
    expect(e2.get<Position>().value.y, 0);

    e2 += Selected();

    root.execute();
    root.cleanup();

    expect(e1.get<Position>().value.x, 1);
    expect(e1.get<Position>().value.y, 1);

    expect(e2.get<Position>().value.x, 1);
    expect(e2.get<Position>().value.y, 1);

    expect(e1.hasT<Selected>(), false);
    expect(e2.hasT<Selected>(), false);
  });

  test('Triggered Move System', () {
    var em = EntityManager();
    var root = ReactiveRootSystem(
        entityManager: em, systems: [_TriggeredMoveSystem()]);

    var e1 = em.createEntity()..set(Position(0, 0));

    var e2 = em.createEntity()..set(Position(0, 0));

    root.init();

    for (var i = 0; i < 100; i++) {
      root.execute();
      root.cleanup();
    }

    expect(e1.get<Position>().value.x, 0);
    expect(e1.get<Position>().value.y, 0);

    expect(e2.get<Position>().value.x, 0);
    expect(e2.get<Position>().value.y, 0);

    for (var i = 0; i < 100; i++) {
      em.setUnique(Selected());
      root.execute();
      root.cleanup();
    }

    expect(e1.get<Position>().value.x, 100);
    expect(e1.get<Position>().value.y, 100);

    expect(e2.get<Position>().value.x, 100);
    expect(e2.get<Position>().value.y, 100);
  });

  test('Feature system', () {
    /// Root's EntityManager
    var rootEM = EntityManager();

    /// Root's counter starts at 0
    rootEM.setUnique(CounterComponent(0));

    /// Declare RootSystem that uses Root's EntityManager
    var root = RootSystem(entityManager: rootEM, systems: [UpdateCounter()]);

    root.execute();

    /// Root's counter incremented by 1
    expect(rootEM.getUnique<CounterComponent>().value, 1);

    /// Declare FeatureSystem that holds its own EntityManager and a reference to Root's EntityManager
    var feature = FeatureSystem(
        rootEntityManager: rootEM,
        systems: [UpdateCounter()],
        onCreate: (em, root) {
          /// Copy Root's counter on Feature
          em.setUnique(root.getUnique<CounterComponent>());
        },
        onDestroy: (em, root) {
          /// Copy Feature's counter on Root
          root.setUnique(em.getUnique<CounterComponent>());
        });

    feature.onCreate();

    /// Feature's counter starts at 1
    expect(feature.entityManager.getUnique<CounterComponent>().value, 1);

    for (var i = 0; i < 5; i++) feature.execute();

    /// Feature's counter incremented by 5
    expect(feature.entityManager.getUnique<CounterComponent>().value, 6);

    /// Root's counter unchanged
    expect(rootEM.getUnique<CounterComponent>().value, 1);

    root.execute();

    /// Root's counter incremented by 1
    expect(rootEM.getUnique<CounterComponent>().value, 2);

    /// Destroy Feature
    feature.onDestroy();

    /// Root's counter equal to Feature's last counter
    expect(rootEM.getUnique<CounterComponent>().value, 6);
  });
}

class UpdateCounter extends EntityManagerSystem implements ExecuteSystem {
  @override
  execute() {
    entityManager.updateUnique<CounterComponent>(
        (oldCounter) => CounterComponent(oldCounter.value + 1));
  }
}
