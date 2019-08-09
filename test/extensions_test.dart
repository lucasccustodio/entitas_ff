import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

void main() {
  test('update name', () {
    final entityManager = EntityManager();
    final entity = entityManager.createEntity()..set(Name('Entity'));

    expect(entity.get<Name>().value, 'Entity');

    entity.update<Name>((oldName) => Name('${oldName.value} updated'));

    expect(entity.get<Name>().value, 'Entity updated');
  });

  test("don't do anything if Entity hasn't the component", () {
    final entityManager = EntityManager();
    final entity = entityManager.createEntity()
      ..update<Name>((oldName) => Name('${oldName.value} updated'));

    expect(entity.get<Name>(), null);
  });

  test('Match later when visible is added', () {
    final entityManager = EntityManager();
    final matcher = EntityMatcher(all: [Name, Age], maybe: [Visible]);

    for (var i = 0; i < 20; i++)
      entityManager.createEntity()..set(Name('Ent$i'))..set(Age(i));

    final map = EntityIndex<Name, String>(entityManager, (name) => name.value);

    expect(entityManager.groupMatching(matcher).entities.length, 20);

    map['Ent1'].set(Visible());

    expect(entityManager.groupMatching(matcher).entities.length, 20);

    map['Ent1'].remove<Visible>();

    expect(entityManager.groupMatching(matcher).entities.length, 20);

    map['Ent1'].remove<Name>();

    expect(entityManager.groupMatching(matcher).entities.length, 19);
  });

  test('BlacklistEntity', () {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    final e = testEntityManager.createBlacklistEntity([Score])
      ..addObserver(TestObserver())
      ..set(CounterComponent(100));

    e.set(Score(0));
    e.set(Score(1));
    e.remove<Score>();

    e.set(CounterComponent(50));
    e.remove<CounterComponent>();
  });

  test('BroadcastEntity', () {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    final source = testEntityManager.createBroadcastEntity()
      ..addObserver(TestObserver());

    final receiver = testEntityManager.createEntity()
      ..addObserver(TestObserver());

    source.addEntity(receiver);

    source.set(Age(500));

    expect(receiver.get<Age>().value, 500);
  });

  test('BroadcastEntity + BlacklistEntity', () {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    final source = testEntityManager.createBroadcastEntity()
      ..addObserver(TestObserver());

    final receiver = testEntityManager.createBlacklistEntity([Age])
      ..addObserver(TestObserver());

    source.addEntity(receiver);

    source.set(Age(500));

    expect(receiver.get<Age>().value, 500);
  });

  test('BroadcastEntity + BroadcastEntity + BlacklistEntity', () {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    final source = testEntityManager.createBroadcastEntity()
      ..addObserver(TestObserver());

    final receiver = testEntityManager.createBroadcastEntity()
      ..addObserver(TestObserver());

    for (int i = 0; i < 5; i++) {
      final e = testEntityManager.createBlacklistEntity([Age])
        ..addObserver(TestObserver());

      receiver.addEntity(e);
    }

    source.addEntity(receiver);

    source.set(Age(500));

    expect(receiver.get<Age>().value, 500);
    expect(receiver.entities.any((e) => e.get<Age>().value != 500), false);
  });
}

class TestObserver implements EntityObserver {
  @override
  void destroyed(ObservableEntity e) {}

  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {}
}
