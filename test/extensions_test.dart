import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

main() {
  test('update name', () {
    var entityManager = EntityManager();
    var entity = entityManager.createEntity();

    entity.set(Name("Entity"));

    expect(entity.get<Name>().value, "Entity");

    entity.update<Name>((oldName) => Name(oldName.value + " updated"));

    expect(entity.get<Name>().value, "Entity updated");
  });

  test("don't do anything if Entity hasn't the component", () {
    var entityManager = EntityManager();
    var entity = entityManager.createEntity();

    entity.update<Name>((oldName) => Name(oldName.value + " updated"));

    expect(entity.get<Name>(), null);
  });

  test('Match later when visible is added', () {
    var entityManager = EntityManager();
    var matcher = EntityMatcher(all: [Name, Age], maybe: [Visible]);

    for (var i = 0; i < 20; i++)
      entityManager.createEntity()..set(Name("Ent$i"))..set(Age(i));

    var map = EntityIndex<Name, String>(entityManager, (name) => name.value);

    expect(entityManager.groupMatching(matcher).entities.length, 20);

    map["Ent1"].set(Visible());

    expect(entityManager.groupMatching(matcher).entities.length, 20);

    map["Ent1"].remove<Visible>();

    expect(entityManager.groupMatching(matcher).entities.length, 20);

    map["Ent1"].remove<Name>();

    expect(entityManager.groupMatching(matcher).entities.length, 19);
  });

  test('getUniques', () {
    var entityManager = EntityManager();

    entityManager.setUnique(CounterComponent(0));
    entityManager.setUnique(Score(0));

    var list = entityManager.getUniques([CounterComponent, Score]);

    expect(list.entities.length, 2);

    expect(list[0].get<CounterComponent>().counter, 0);
    expect(list[1].get<Score>().value, 0);

    entityManager.setUnique(CounterComponent(1));
    entityManager.setUnique(Score(1));

    expect(list[0].get<CounterComponent>().counter, 1);
    expect(list[1].get<Score>().value, 1);
  });

  test('getUniquesNamed', () {
    var entityManager = EntityManager();

    entityManager.setUnique(CounterComponent(0));
    entityManager.setUnique(Score(0));

    var map = entityManager
        .getUniquesNamed({'counter': CounterComponent, 'score': Score});

    expect(map.entities.length, 2);

    expect(map['counter'].get<CounterComponent>().counter, 0);
    expect(map['score'].get<Score>().value, 0);

    entityManager.setUnique(CounterComponent(1));
    entityManager.setUnique(Score(1));

    expect(map['counter'].get<CounterComponent>().counter, 1);
    expect(map['score'].get<Score>().value, 1);
  });
}
