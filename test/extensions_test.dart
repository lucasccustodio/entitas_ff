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

  /* flutterTest.testWidgets('fallback when null', (tester) async {
    var entityManager = EntityManager();

    await tester.pumpWidget(EntityManagerProvider(
      entityManager: entityManager,
      child: MaterialApp(
        home: EntityObservingWidget(
          provider: (em) => em.getUniqueEntity<CounterComponent>(),
          builder: (e, context) =>
              Text("Counter: ${e.get<CounterComponent>().counter}"),
        ),
      ),
    ));

    await tester.pump(Duration.zero);

    expect(flutterTest.find.text("Counter: 0"), flutterTest.findsOneWidget);
  }); */
}
