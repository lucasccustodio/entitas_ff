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
}

class TestObserver implements EntityObserver {
  @override
  void destroyed(ObservableEntity e) {}

  @override
  void exchanged(ObservableEntity e, ComponentMixin oldC, ComponentMixin newC) {}
}
