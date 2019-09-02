import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'components.dart';

main() {
  testWidgets('AnimatableEntityObservingWidget [Entity]', (tester) async {
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
            animateUpdated: (oldC, newC) {
              return (newC is CounterComponent && newC.value == 0)
                  ? EntityAnimation.reverse
                  : EntityAnimation.forward;
            },
            builder: (entity, animations, context) {
              return Column(
                children: <Widget>[
                  Text("Counter: ${entity.get<CounterComponent>().value}"),
                  Text("Animation: ${animations['counter'].value}")
                ],
              );
            },
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
        (old) => CounterComponent(old.value + 1));

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

  testWidgets('AnimatableEntityObservingWidget [Entity]', (tester) async {
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
            onAnimationEnd: print,
            animateUpdated: (oldC, newC) {
              return (newC is CounterComponent && newC.value == 0)
                  ? EntityAnimation.reverse
                  : EntityAnimation.forward;
            },
            builder: (entity, animations, context) {
              return Column(
                children: <Widget>[
                  Text("Counter: ${entity.get<CounterComponent>().value}"),
                  Text("Animation: ${animations['counter'].value}")
                ],
              );
            },
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
        (old) => CounterComponent(old.value + 1));

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

  testWidgets('AnimatableEntityObservingWidget [Entity provided]', (tester) async {
    /// Instantiate our EntityManager
    var testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    final entity = testEntityManager.createEntity()..set(Age(0));

    /// Pump our EntityManagerProvider
    await tester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: AnimatableEntityObservingWidget(
            provider: (em) => entity,
            duration: Duration(seconds: 5),
            tweens: {'counter': IntTween(begin: 0, end: 100)},
            onAnimationEnd: print,
            animateUpdated: (oldC, newC) {
              return (newC is Age && newC.value == 0)
                  ? EntityAnimation.reverse
                  : EntityAnimation.forward;
            },
            builder: (entity, animations, context) {
              return Column(
                children: <Widget>[
                  Text("Counter: ${entity.get<Age>().value}"),
                  Text("Animation: ${animations['counter'].value}")
                ],
              );
            },
          ),
        ),
      ),
    );

    /// By default counter should be at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// By default animation should be stopped
    expect(find.text("Animation: 0"), findsOneWidget);

    /// Increase the counter
    entity.update<Age>((old) => Age(old.value + 1));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be at 1
    expect(find.text("Counter: 1"), findsOneWidget);

    /// Now animation should be completed
    expect(find.text("Animation: 100"), findsOneWidget);

    /// Set counter back to 0
    entity.set(Age(0));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be back at 0
    expect(find.text("Counter: 0"), findsOneWidget);

    /// Now animation should have completed at reverse
    expect(find.text("Animation: 0"), findsOneWidget);
  });

  testWidgets('AnimatableEntityObservingWidget [Entity] + blacklist',
      (tester) async {
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
            onAnimationEnd: print,
            startAnimating: false,
            blacklist: const [CounterComponent],
            builder: (entity, animations, context) {
              return Column(
                children: <Widget>[
                  Text("Counter: ${entity.get<CounterComponent>().value}"),
                  Text("Animation: ${animations['counter'].value}")
                ],
              );
            },
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
        (old) => CounterComponent(old.value + 1));

    /// Advance until animation is completed
    await tester.pumpAndSettle();

    /// Now counter's text should be at 1
    expect(find.text("Counter: 0"), findsOneWidget);

    /// Now animation should be completed
    expect(find.text("Animation: 0"), findsOneWidget);
  });

  testWidgets('AnimatableEntityObservingWidget is disposed correctly',
      (tester) async {
    /// Instantiate our EntityManager
    var testEntityManager = EntityManager();

    /// Instantiate TestComponent and set counter to 0
    final e = testEntityManager.createEntity()..set(CounterComponent(100));

    /// Pump our EntityManagerProvider
    await tester.pumpWidget(
      EntityManagerProvider(
        entityManager: testEntityManager,
        child: MaterialApp(
          home: AnimatableEntityObservingWidget(
            provider: (_) => e,
            duration: Duration(seconds: 5),
            startAnimating: true,
            tweens: {'counter': IntTween(begin: 0, end: 100)},
            builder: (entity, animations, context) {
              return Column(
                children: <Widget>[
                  Text("Counter: ${entity.get<CounterComponent>()?.value}"),
                  Text("Animation: ${animations['counter'].value}")
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pump(Duration.zero);

    e.destroy();

    await tester.pumpAndSettle();

    tester.verifyTickersWereDisposed();
  });
}
