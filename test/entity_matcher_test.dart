import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

void main() {
  test('Matcher equality', () {
    expect(EntityMatcher(all: [Name, Age]) == EntityMatcher(all: [Name, Age]),
        true);
    expect(EntityMatcher(all: [Name, Age]) == EntityMatcher(all: [Age, Name]),
        true);
    expect(
        EntityMatcher(all: [Name, Age]) == EntityMatcher(all: [Name]), false);
    expect(EntityMatcher(all: [Age]) == EntityMatcher(all: [Name]), false);
    expect(EntityMatcher(all: [Age]) == EntityMatcher(all: [Age, Name]), false);
    expect(EntityMatcher(any: [Name, Age]) == EntityMatcher(any: [Age, Name]),
        true);
    expect(
        EntityMatcher(any: [Name, Age, Age]) ==
            EntityMatcher(any: [Age, Name, Name]),
        true);
    expect(
        EntityMatcher(
                all: [Name, Age, Age],
                any: [Position, Velocity],
                none: [Selected]) ==
            EntityMatcher(
                all: [Age, Name], any: [Velocity, Position], none: [Selected]),
        true);
  });

  test('Matcher hashcode', () {
    expect(
        EntityMatcher(all: [Name, Age]).hashCode ==
            EntityMatcher(all: [Name, Age]).hashCode,
        true);
    expect(
        EntityMatcher(all: [Name, Age]).hashCode ==
            EntityMatcher(all: [Age, Name]).hashCode,
        true);
    expect(
        EntityMatcher(all: [Name, Age]).hashCode ==
            EntityMatcher(all: [Name]).hashCode,
        false);
    expect(
        EntityMatcher(all: [Age]).hashCode ==
            EntityMatcher(all: [Name]).hashCode,
        false);
    expect(
        EntityMatcher(all: [Age]).hashCode ==
            EntityMatcher(all: [Age, Name]).hashCode,
        false);
    expect(
        EntityMatcher(any: [Name, Age]).hashCode ==
            EntityMatcher(any: [Age, Name]).hashCode,
        true);
    expect(
        EntityMatcher(any: [Name, Age, Age]).hashCode ==
            EntityMatcher(any: [Age, Name, Name]).hashCode,
        true);
  });

  test('Matcher contains type', () {
    expect(EntityMatcher(all: [Name, Age]).containsType(Name), true);
    expect(EntityMatcher(all: [Name, Age]).containsType(Age), true);
    expect(EntityMatcher(all: [Name, Age]).containsType(Position), false);
    expect(
        EntityMatcher(all: [Name, Age], any: [Position, Velocity])
            .containsType(Position),
        true);
    expect(
        EntityMatcher(all: [Name, Age], any: [Position, Velocity])
            .containsType(Velocity),
        true);
    expect(
        EntityMatcher(all: [Name, Age], any: [Position, Velocity])
            .containsType(Name),
        true);
    expect(
        EntityMatcher(all: [Name, Age], any: [Position, Velocity])
            .containsType(Selected),
        false);
    expect(
        EntityMatcher(
            all: [Name, Age],
            any: [Position, Velocity],
            none: [Selected]).containsType(Selected),
        true);
  });

  test('Matcher copyWith', () {
    var entityManager = EntityManager();

    var entity = entityManager.createEntity()..set(Name(''))..set(Age(0));

    var matcher = EntityMatcher(all: [Name, Age]);

    expect(matcher.matches(entity), true);

    var matcherExcludingAge = matcher.copyWith(all: [Name], none: [Age]);

    expect(matcher.hashCode != matcherExcludingAge.hashCode, true);

    expect(matcherExcludingAge.matches(entity), false);
  });

  test('Matcher extend', () {
    var entityManager = EntityManager();

    var entity = entityManager.createEntity()..set(Name(''))..set(Age(0));

    var matcher = EntityMatcher(all: [Name, Age]);

    expect(matcher.matches(entity), true);

    var matcherWithSelected = matcher.extend(all: [Selected]);

    expect(matcher.hashCode != matcherWithSelected.hashCode, true);

    expect(matcherWithSelected.matches(entity), false);
  });

  test('Matcher stric mode', () {
    var entityManager = EntityManager();

    var entity = entityManager.createEntity()..set(Name('Jack'))..set(Age(0));

    var matcher =
        EntityMatcher.strict(all: [Name, Age], values: {Name: EqualComponents(Name('John'))});

    expect(matcher.matches(entity), false);
  });
}
