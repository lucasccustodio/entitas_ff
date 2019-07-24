import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'components.dart';

main() {
  testWidgets('EntityListObservingWidget', (tester) async {
    /// Instantiate our EntityManager
    var testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    testEntityManager.setUnique(CounterComponent(0));

    testEntityManager.setUnique(Score(0));

    /// Pump our EntityManagerProvider
    await tester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: EntityListObservingWidget(
            provider: (em) => EntityList(entityList: [
              em.getUniqueEntity<CounterComponent>(),
              em.getUniqueEntity<Score>()
            ]),
            builder: (entity, context) => Column(
              children: <Widget>[
                Text("Counter: ${entity[0].get<CounterComponent>().counter}"),
                Text("Score: ${entity[1].get<Score>().value}")
              ],
            ),
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    expect(find.text("Score: 0"), findsOneWidget);

    /// Increase the counter
    testEntityManager.updateUnique<CounterComponent>(
        (old) => CounterComponent(old.counter + 1));

    /// Advance one frame
    await tester.pump(Duration.zero);

    /// Now counter's text should be at 1
    expect(find.text("Counter: 1"), findsOneWidget);

    expect(find.text("Score: 0"), findsOneWidget);

    testEntityManager.updateUnique<Score>((old) => Score(old.value + 1));

    /// Advance one frame
    await tester.pump(Duration.zero);

    expect(find.text("Score: 1"), findsOneWidget);

    testEntityManager.updateUnique<Score>((old) => Score(old.value + 1));

    testEntityManager.updateUnique<CounterComponent>(
        (old) => CounterComponent(old.counter + 1));

    /// Advance one frame
    await tester.pump(Duration.zero);

    expect(find.text("Counter: 2"), findsOneWidget);

    expect(find.text("Score: 2"), findsOneWidget);
  });

  testWidgets('EntityMapObservingWidget', (tester) async {
    /// Instantiate our EntityManager
    var testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    testEntityManager.setUnique(CounterComponent(0));

    testEntityManager.setUnique(Score(0));

    /// Pump our EntityManagerProvider
    await tester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: EntityMapObservingWidget(
            provider: (em) => EntityMap(entityMap: {
              'counter': em.getUniqueEntity<CounterComponent>(),
              'score': em.getUniqueEntity<Score>()
            }),
            builder: (entity, context) => Column(
              children: <Widget>[
                Text(
                    "Counter: ${entity['counter'].get<CounterComponent>().counter}"),
                Text("Score: ${entity['score'].get<Score>().value}")
              ],
            ),
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    expect(find.text("Score: 0"), findsOneWidget);

    /// Increase the counter
    testEntityManager.updateUnique<CounterComponent>(
        (old) => CounterComponent(old.counter + 1));

    /// Advance one frame
    await tester.pump(Duration.zero);

    /// Now counter's text should be at 1
    expect(find.text("Counter: 1"), findsOneWidget);

    /// But score's text should still be at 0
    expect(find.text("Score: 0"), findsOneWidget);

    testEntityManager.updateUnique<Score>((old) => Score(old.value + 1));

    /// Advance one frame
    await tester.pump(Duration.zero);

    /// Now score's text should be at 1
    expect(find.text("Score: 1"), findsOneWidget);

    /// Increase both
    testEntityManager
      ..updateUnique<Score>((old) => Score(old.value + 1))
      ..updateUnique<CounterComponent>(
          (old) => CounterComponent(old.counter + 1));

    /// Advance one frame
    await tester.pump(Duration.zero);

    /// Both should be at 2
    expect(find.text("Counter: 2"), findsOneWidget);
    expect(find.text("Score: 2"), findsOneWidget);
  });

  testWidgets('AnimatableEntityObservingWidget', (tester) async {
    /// Instantiate our EntityManager
    var testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    testEntityManager.setUnique(CounterComponent(0));

    testEntityManager.setUnique(Score(0));

    /// Pump our EntityManagerProvider
    await tester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: AnimatableEntityObservingWidget(
            provider: (em) => em.getUniqueEntity<CounterComponent>(),
            duration: Duration(seconds: 5),
            tweens: {'counter': IntTween(begin: 0, end: 100)},
            animateUpdated: (oldC, newC) =>
                (newC is CounterComponent && newC.counter == 0) ? -1 : 0,
            builder: (entity, animations, context) => Column(
              children: <Widget>[
                Text("Counter: ${entity.get<CounterComponent>().counter}"),
                Text("Animation: ${animations['counter'].value}")
              ],
            ),
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// By default animation should be stopped
    expect(find.text("Animation: 0"), findsOneWidget);

    /// Increase the counter
    testEntityManager.updateUnique<CounterComponent>(
        (old) => CounterComponent(old.counter + 1));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be at 1
    expect(find.text("Counter: 1"), findsOneWidget);

    /// Now animation should be completed
    expect(find.text("Animation: 100"), findsOneWidget);

    /// Set counter back to 0
    testEntityManager.setUnique(CounterComponent(0));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be back at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// Now animation should have completed at reverse
    expect(find.text("Animation: 0"), findsOneWidget);
  });

  testWidgets('AnimatableEntityMapObservingWidget', (tester) async {
    /// Instantiate our EntityManager
    var testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    testEntityManager.setUnique(CounterComponent(0));

    testEntityManager.setUnique(Score(0));

    /// Pump our EntityManagerProvider
    await tester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: AnimatableEntityMapObservingWidget(
            provider: (em) => EntityMap(entityMap: {
              'counter': em.getUniqueEntity<CounterComponent>(),
              'score': em.getUniqueEntity<Score>()
            }),
            duration: Duration(seconds: 5),
            tweens: {'counter': IntTween(begin: 0, end: 100)},
            animateUpdated: (oldC, newC) =>
                (newC is CounterComponent && newC.counter == 0) ? -1 : 0,
            builder: (entity, animations, context) => Column(
              children: <Widget>[
                Text(
                    "Counter: ${entity['counter'].get<CounterComponent>().counter}"),
                Text("Score: ${entity['score'].get<Score>().value}"),
                Text("Animation: ${animations['counter'].value}")
              ],
            ),
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// By default animation should be stopped
    expect(find.text("Animation: 0"), findsOneWidget);

    /// Increase the counter
    testEntityManager.updateUnique<CounterComponent>(
        (old) => CounterComponent(old.counter + 1));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be at 1
    expect(find.text("Counter: 1"), findsOneWidget);

    /// Now animation should be completed
    expect(find.text("Animation: 100"), findsOneWidget);

    /// Set counter back to 0
    testEntityManager.setUnique(CounterComponent(0));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be back at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// Now animation should have completed at reverse
    expect(find.text("Animation: 0"), findsOneWidget);
  });

  testWidgets('AnimatableEntityListObservingWidget', (tester) async {
    /// Instantiate our EntityManager
    var testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    testEntityManager.setUnique(CounterComponent(0));

    testEntityManager.setUnique(Score(0));

    /// Pump our EntityManagerProvider
    await tester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: AnimatableEntityListObservingWidget(
            provider: (em) => EntityList(entityList: [
              em.getUniqueEntity<CounterComponent>(),
              em.getUniqueEntity<Score>()
            ]),
            duration: Duration(seconds: 5),
            tweens: {'counter': IntTween(begin: 0, end: 100)},
            animateUpdated: (oldC, newC) =>
                (newC is CounterComponent && newC.counter == 0) ? -1 : 0,
            builder: (entity, animations, context) => Column(
              children: <Widget>[
                Text("Counter: ${entity[0].get<CounterComponent>().counter}"),
                Text("Score: ${entity[1].get<Score>().value}"),
                Text("Animation: ${animations['counter'].value}")
              ],
            ),
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// By default animation should be stopped
    expect(find.text("Animation: 0"), findsOneWidget);

    /// Increase the counter
    testEntityManager.updateUnique<CounterComponent>(
        (old) => CounterComponent(old.counter + 1));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be at 1
    expect(find.text("Counter: 1"), findsOneWidget);

    /// Now animation should be completed
    expect(find.text("Animation: 100"), findsOneWidget);

    /// Set counter back to 0
    testEntityManager.setUnique(CounterComponent(0));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be back at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// Now animation should have completed at reverse
    expect(find.text("Animation: 0"), findsOneWidget);
  });
}
