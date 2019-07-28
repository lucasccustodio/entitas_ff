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
              return (newC is CounterComponent && newC.counter == 0)
                  ? EntityAnimation.reverse
                  : EntityAnimation.forward;
            },
            builder: (entity, animations, context) {
              return Column(
                children: <Widget>[
                  Text("Counter: ${entity.get<CounterComponent>().counter}"),
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
