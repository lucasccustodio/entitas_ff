import 'package:flutter/material.dart';
import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter_test/flutter_test.dart';

import 'components.dart';

//An UniqueComponent can only be held by a single entity at a time
class TestComponent = ComponentData<int> with UniqueMixin;

class CounterComponent = ComponentData<int> with ComponentMixin;

class IsMatchComponent = TagComponent with ComponentMixin;

void main() async {
  testWidgets('EntityManagerProvider', (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));

    /// Pump our EntityManagerProvider
    await widgetTester.pumpWidget(EntityManagerProvider(
      entityManager: testEntityManager,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            final em = EntityManagerProvider.of(context).entityManager;
            final counter = em.getUnique<TestComponent>().value;

            return Text('Counter: $counter');
          },
        ),
      ),
    ));

    /// By default counter should be at 0
    expect(find.text('Counter: 0'), findsOneWidget);
  });

  testWidgets('EntityObservingWidget', (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));

    /// Pump our EntityManagerProvider
    await widgetTester.pumpWidget(EntityManagerProvider(
      entityManager: testEntityManager,
      child: MaterialApp(
        home: EntityObservingWidget(
            provider: (em) => em.getUniqueEntity<TestComponent>(),
            builder: (entity, context) =>
                Text('Counter: ${entity.get<TestComponent>().value}')),
      ),
    ));

    /// By default counter should be at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// Increase the counter
    testEntityManager
        .updateUnique<TestComponent>((old) => TestComponent(old.value + 1));

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Now counter's text should be at 1
    expect(find.text('Counter: 1'), findsOneWidget);
  });

  testWidgets('EntityObservingWidget.extended rebuild only updated',
      (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));

    /// Pump our EntityManagerProvider
    await widgetTester.pumpWidget(EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: EntityObservingWidget.extended(
            rebuildAdded: (_) => false,
            rebuildRemoved: (_) => false,
            rebuildUpdated: (_, __) => true,
            provider: (em) => em.getUniqueEntity<TestComponent>(),
            builder: (entity, context) => Column(
              children: <Widget>[
                Text('Counter: ${entity.get<TestComponent>().value}'),
                if (entity.hasT<IsSelected>())
                  Text('Selected: ${entity.get<IsSelected>().value}')
              ],
            ),
          ),
        )));

    /// By default counter text at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// By default no selected text
    expect(find.text('Selected: false'), findsNothing);

    /// Add IsSelected
    testEntityManager
        .getUniqueEntity<TestComponent>()
        .set(IsSelected(value: false));

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Still no selected text
    expect(find.text('Selected: false'), findsNothing);

    /// Update IsSelected
    testEntityManager
        .getUniqueEntity<TestComponent>()
        .set(IsSelected(value: true));

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Now selected text is visible and updated
    expect(find.text('Selected: true'), findsOneWidget);
  });

  testWidgets('EntityObservingWidget.extended rebuild only added',
      (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));

    /// Pump our EntityManagerProvider
    await widgetTester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: EntityObservingWidget.extended(
            rebuildAdded: (c) => c is IsSelected,
            rebuildUpdated: (_, __) => false,
            provider: (em) => em.getUniqueEntity<TestComponent>(),
            builder: (entity, context) => Column(
              children: <Widget>[
                Text('Counter: ${entity.get<TestComponent>().value}'),
                if (entity.hasT<IsSelected>())
                  Text('Selected: ${entity.get<IsSelected>().value}')
              ],
            ),
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// By default counter should be at 0
    expect(find.text('Selected: false'), findsNothing);

    /// Increase the counter
    testEntityManager
        .updateUnique<TestComponent>((old) => TestComponent(old.value + 1));

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Now counter's text should still be at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// Increase the counter
    testEntityManager.getUniqueEntity<TestComponent>().set(IsSelected());

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Now should have a selected text
    expect(find.text('Selected: false'), findsOneWidget);

    /// Updated selected
    testEntityManager
        .getUniqueEntity<TestComponent>()
        .set(IsSelected(value: true));

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Should still be false
    expect(find.text('Selected: true'), findsNothing);
  });

  testWidgets('EntityObservingWidget.extended rebuild only removed',
      (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager()
      ..setUnique(TestComponent(0)).set(IsSelected(value: true));

    /// Pump our EntityManagerProvider
    await widgetTester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: EntityObservingWidget.extended(
            rebuildRemoved: (c) => c is IsSelected,
            rebuildAdded: (c) => false,
            rebuildUpdated: (_, ___) => false,
            provider: (em) => em.getUniqueEntity<TestComponent>(),
            builder: (entity, context) => Column(
              children: <Widget>[
                Text('Counter: ${entity.get<TestComponent>().value}'),
                if (entity.hasT<IsSelected>())
                  Text('Selected: ${entity.get<IsSelected>().value}')
              ],
            ),
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// By default counter should be at 0
    expect(find.text('Selected: true'), findsOneWidget);

    /// Increase the counter
    testEntityManager
        .updateUnique<TestComponent>((old) => TestComponent(old.value + 1));

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Now counter's text should still be at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// Increase the counter
    testEntityManager.getUniqueEntity<TestComponent>().remove<IsSelected>();

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Now should have a selected text
    expect(find.text('Selected: true'), findsNothing);

    /// Updated selected
    testEntityManager
        .getUniqueEntity<TestComponent>()
        .set(IsSelected(value: false));

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Should still be false
    expect(find.text('Selected: false'), findsNothing);
  });

  testWidgets('GroupObservingWidget', (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager();

    /// Pump our EntityManagerProvider
    await widgetTester.pumpWidget(EntityManagerProvider(
      entityManager: testEntityManager,
      child: MaterialApp(
        home: GroupObservingWidget(
            matcher: EntityMatcher(all: [CounterComponent, IsMatchComponent]),
            builder: (group, context) =>
                Text('Counter: ${group.entities.length}')),
      ),
    ));

    /// By default counter should be at 0 since there's no matched entities
    expect(find.text('Counter: 0'), findsOneWidget);

    /// Instantiate some entities to match
    for (var i = 0; i < 5; i++) {
      testEntityManager.createEntity()
        ..set(CounterComponent(i))
        ..set(IsMatchComponent());
    }

    /// Advance one frame
    await widgetTester.pump(Duration.zero);

    /// Counter's text should be at 5
    expect(find.text('Counter: 5'), findsOneWidget);
  });

  testWidgets('Root system', (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));

    /// Pump our Feature EntityManagerProvider
    await widgetTester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        system: RootSystem(
            entityManager: testEntityManager, systems: [TestSystem()]),
        child: MaterialApp(home: Builder(
          builder: (context) {
            return Scaffold(
              body: EntityObservingWidget(
                provider: (em) => em.getUniqueEntity<TestComponent>(),
                builder: (entity, context) =>
                    Text('Counter: ${entity.get<TestComponent>().value}'),
              ),
            );
          },
        )),
      ),
    );

    /// Root's counter should start at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// Advance 5 frames ie: make TestSystem tick 5 times
    for (var i = 0; i < 5; i++) {
      await widgetTester.pump(Duration.zero);
    }

    /// 500 frames passed but we need to account for the fact that ExecuteSystem starting ticking immediately and that pageBack() also takes a frame
    expect(find.text('Counter: 5'), findsOneWidget);
  });

  testWidgets('Feature system', (widgetTester) async {
    /// Instantiate our EntityManager
    final testEntityManager = EntityManager()..setUnique(TestComponent(0));

    /// Pump our Feature EntityManagerProvider
    await widgetTester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
            home: Builder(
          builder: (context) => Scaffold(
            floatingActionButton: FloatingActionButton(
              child: Text('Start feature'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Scaffold(
                          appBar: AppBar(),
                          body: EntityManagerProvider.feature(
                            child: Text('Feature running'),
                            system: FeatureSystem(
                                rootEntityManager:
                                    EntityManagerProvider.of(context)
                                        .entityManager,
                                systems: [TestSystem()],

                                /// When created sets the initial counter to Root's
                                onCreate: (em, root) {
                                  final counter =
                                      root.getUnique<TestComponent>().value;

                                  /// Uncomment to see how the lifecycle works
                                  /* print(
                                      'Feature\'s counter start at: $counter'); */
                                  em.setUnique(TestComponent(counter));
                                },

                                /// When destroyed set Root's counter to the last known value
                                onDestroy: (em, root) {
                                  final counter =
                                      em.getUnique<TestComponent>().value;

                                  /// Uncomment to see how the lifecycle works
                                  /* print(
                                      'Feature\'s counter ended at: $counter'); */
                                  root.setUnique(TestComponent(counter));
                                }),
                          ),
                        )));
              },
            ),
            body: EntityObservingWidget(
              provider: (em) => em.getUniqueEntity<TestComponent>(),
              builder: (e, context) =>
                  Text('Counter: ${e.get<TestComponent>().value}'),
            ),
          ),
        )),
      ),
    );

    /// Root's counter should start at 0
    expect(find.text('Counter: 0'), findsOneWidget);

    /// Push Feature atop of the stack
    await widgetTester.tap(find.text('Start feature'));

    /// Advance 5 frames ie: make TestSystem tick 5 times
    for (var i = 0; i < 5; i++) {
      await widgetTester.pump(Duration.zero);
    }

    /// Pop the Feature to dispose of it
    await widgetTester.pageBack();

    /// Should take a few frames for the Root get rebuilt and update counter's text
    await widgetTester.pumpAndSettle();

    /// Counter should now be at 5
    expect(find.text('Counter: 5'), findsOneWidget);
  });
}

class TestSystem extends EntityManagerSystem implements ExecuteSystem {
  @override
  void execute() {
    entityManager
        .updateUnique<TestComponent>((old) => TestComponent(old.value + 1));
  }
}
