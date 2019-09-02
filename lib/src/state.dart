import 'package:meta/meta.dart';

/// Defines an interface which every component class needs to implement.
///
/// ### Example
///
///     class NameComponent implements Component {
///       final String value;
///       Name(this.value);
///     }
@immutable
abstract class Component {}

/// Defines an interface which every unique component class needs to implement.
/// Unique means that there can be only one instance of this component set on an [Entity] per [EntityManager]
///
/// ### Example
///
///     class SelectedComponent implements UniqueComponent {}
///
@immutable
abstract class UniqueComponent extends Component {}

/// Interface which you need to implement if you want to observe changes on an [Entity] instance
abstract class EntityObserver {
  /// Called after the destroy method is called on the entity and all components are removed.
  void destroyed(ObservableEntity e);

  /// Called after a component was added exchanged or removed from an [Entity] instance.
  /// When a component was added, it is reflected in `newC` and `oldC` is `null`.
  /// When a component was removed, old component is reflected in `oldC` and `newC` is `null`.
  /// When a component was exchanged, old and new components are refelcted in `oldC` and `newC` respectively.
  void exchanged(ObservableEntity e, Component oldC, Component newC);
}

// Interface for an Entity instance that can be observed for changes
abstract class ObservableEntity {
  ObservableEntity(this.creationIndex, EntityObserver mainObserver)
      : _mainObserver = mainObserver;

  final int creationIndex;
  final EntityObserver _mainObserver;
  bool isAlive = true;
  void checkIsAlive() {
    assert(isAlive, 'Calling + Component on destroyed entity');
  }

  // Holding all components map through their type.
  final Map<Type, Component> _components = {};
  // Holding all obeservers.
  final Set<EntityObserver> _observers = {};

  /// Returns component instance by type or `null` if not present.
  T get<T extends Component>() {
    final c = _components[T];
    if (c == null) {
      return null;
    }
    return c;
  }

  /// Adds component instance to the entity.
  /// If the entity already has a component of the same instance, the component will be replaced with provided one.
  /// After the component is set, all observers are notified.
  /// Calling this operator on a destroyed entity is considerered an error.
  ObservableEntity operator +(Component c) {
    checkIsAlive();
    final oldC = _components[c.runtimeType];
    _components[c.runtimeType] = c;
    _mainObserver.exchanged(this, oldC, c);
    for (var o in _observerList) {
      o.exchanged(this, oldC, c);
    }
    return this;
  }

  /// Internally just calls the `+` operator.
  /// Introduced inorder to support cascade notation.
  void set(Component c) {
    final _ = this + c;
  }

  /// Removes component from the entity.
  /// If component of the given type was not present on the entity, nothing happens.
  /// The observers are notified only if there was a component removed.
  /// Calling this operator on a destroyed entity is considerered an error.
  ObservableEntity operator -(Type t) {
    checkIsAlive();
    final c = _components[t];
    if (c != null) {
      _components.remove(t);
      _mainObserver.exchanged(this, c, null);
      for (var o in _observerList) {
        o.exchanged(this, c, null);
      }
    }

    return this;
  }

  /// Internally just calls the `-` operator.
  /// Introduced inorder to support cascade notation.
  void remove<T extends Component>() {
    final _ = this - T;
  }

  /// Check if entity hold a component of the given type.
  bool has(Type t) {
    return _components.containsKey(t);
  }

  /// Same as `has` method just with generics.
  bool hasT<T extends Component>() {
    return _components.containsKey(T);
  }

  /// Updates a given component on Entity if present and updateTo's result isn't `null`;
  void update<T extends Component>(T updateTo(T prev)) {
    if (!hasT<T>()) {
      return;
    }

    final oldComponent = get<T>();
    final newComponent = updateTo(oldComponent);

    final _ = this + (newComponent ?? oldComponent);
  }

  /// Adds observer to the entity which will be notified on every mutating action.
  /// Observers are stored in a [Set].
  void addObserver(EntityObserver o) {
    _observers.add(o);
    __observerList = null;
  }

  /// Remove an observer form the [Set] of observers.
  void removeObserver(EntityObserver o) {
    _observers.remove(o);
    __observerList = null;
  }

  /// Destroy an entity which will lead to following steps:
  /// 1. Remove all components
  /// 2. Notify all observers
  /// 3. Remove all observers
  /// 4. Set `isAlive` to `false`.
  void destroy() {
    for (var comp in _components.keys.toList()) {
      final _ = this - comp;
    }
    _mainObserver.destroyed(this);
    for (var o in _observerList) {
      o.destroyed(this);
    }
    _components.clear();
    _observers.clear();
    __observerList = null;
    isAlive = false;
  }

  /// An entity is equal to other if `creationIndex` and `_mainObserver` are equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity &&
          runtimeType == other.runtimeType &&
          creationIndex == other.creationIndex &&
          identical(_mainObserver, other._mainObserver);

  /// We use `creationIndex` as hashcode
  @override
  int get hashCode => creationIndex;

  // Caching the observer list, so that when observers are called they can safely remove themselves as observers
  List<EntityObserver> __observerList;
  List<EntityObserver> get _observerList {
    return __observerList ??= List.unmodifiable(_observers);
  }
}

/// Class which represents an entity instance.
/// An instance of an entity can be created only through an `EntityManger`.
/// ### Example
///   EntityManager em = EntityManager();
///   Entity e = em.createEntity();
class Entity extends ObservableEntity {
  Entity._(int creationIndex, EntityObserver mainObserver)
      : super(creationIndex, mainObserver);
}

/// EntityMatcher can be understood as a query. It can be used to checks if an [Entity] complies with provided rules.
/// ### Example
///   var matcher = EntityMatcher(all: [A, B], any: [C, D] none: [E])
/// For an entity to pass the given `matcher` it needs to contain components of type `A` and `B`. Either `C` or `D`. And no `E`.
/// The provided lists `all`, `any` and `none` are internally translated to a [Set]. This means that order and occurance of duplications is not important.
/// If you provide the `none` list, you have to provide either `all` or `any` none empty list of component types.
class EntityMatcher {
  EntityMatcher(
      {List<Type> all, List<Type> any, List<Type> none, List<Type> maybe})
      : _all = Set.of(all ?? []),
        _any = Set.of(any ?? []),
        _none = Set.of(none ?? []),
        _maybe = Set.of(maybe ?? []) {
    assert(
        (_all != null && _all.isNotEmpty) || (_any != null && _any.isNotEmpty),
        'Matcher needs to have all or any present');
  }

  final Set<Type> _all;
  final Set<Type> _any;
  final Set<Type> _none;
  final Set<Type> _maybe;

  // Returns a copy of this matcher with provided fields changed
  EntityMatcher copyWith(
          {List<Type> all,
          List<Type> none,
          List<Type> any,
          List<Type> maybe}) =>
      EntityMatcher(
          all: all ?? _all.toList(),
          none: none ?? _none.toList(),
          any: any ?? _any.toList(),
          maybe: maybe ?? _maybe.toList());

  // Returns a copy of this matcher with provided fields extended
  EntityMatcher extend(
          {List<Type> all,
          List<Type> none,
          List<Type> any,
          List<Type> maybe}) =>
      EntityMatcher(
          all: [..._all.toList(), if (all != null) ...all],
          none: [..._none.toList(), if (none != null) ...none],
          any: [..._any.toList(), if (any != null) ...any],
          maybe: [..._maybe.toList(), if (maybe != null) ...maybe]);

  /// Checks if the [Entity] contains necessary components.
  bool matches(ObservableEntity e) {
    for (var t in _all) {
      if (e.has(t) == false) {
        return false;
      }
    }
    for (var t in _none) {
      if (e.has(t)) {
        return false;
      }
    }
    if (_any.isEmpty) {
      return true;
    }
    for (var t in _any) {
      if (e.has(t)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if `all`, `any` or `none` contains given type.
  bool containsType(Type t) {
    return _all.contains(t) ||
        _any.contains(t) ||
        _none.contains(t) ||
        _maybe.contains(t);
  }

  /// Matcher are equal if their `all`, `any`, `none` sets overlap.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityMatcher &&
              runtimeType == other.runtimeType &&
              _all.length == other._all.length &&
              _any.length == other._any.length &&
              _none.length == other._none.length &&
              _maybe.length == other._maybe.length &&
              _all.difference(other._all).isEmpty &&
              _any.difference(other._any).isEmpty &&
              _none.difference(other._none).isEmpty) &&
          _maybe.difference(other._maybe).isEmpty;

  /// Different matchers with same `all`, `any`, `none`, `maybe` need to return equal hash code.
  @override
  int get hashCode {
    final a = _all.fold(0, (sum, t) => t.hashCode ^ sum);
    final b = _any.fold(a << 4, (sum, t) => t.hashCode ^ sum);
    final c = _none.fold(b << 4, (sum, t) => t.hashCode ^ sum);
    final d = _maybe.fold(c << 4, (sum, t) => t.hashCode ^ sum);
    return d;
  }
}

/// Interface which you need to implement, if you want to observe changes on [EntityGroup] instance
abstract class GroupObserver {
  void added(EntityGroup group, ObservableEntity entity);
  void updated(EntityGroup group, ObservableEntity entity);
  void removed(EntityGroup group, ObservableEntity entity);
}

/// Group represent a collection of entities, which match a given [EntityMatcher] and is always up to date.
/// It can be instantiated only through an instance of [EntityManager].
/// ### Example
///   EntityManager em = EntityManager();
///   Group g = em.group(all: [Name, Age]);
///
/// Always up to date means that if we create an entity `e` and add components `Name` and `Age` to it, the entity will directly become part of the group g.
///
/// ### Example
///   Entity e = em.createEntity();
///   e += Name("Max");
///   e += Age(37);
///   // e is now accessible through g.
///
///   e -= Name;
///   // e is not part of g any more.
///
/// Groups are observable, see `addObserver`, `removeObserver`.
/// In order to access the entities of the group you need to call `entities` getter
class EntityGroup implements EntityObserver {
  EntityGroup._(this.matcher) : assert(matcher != null);

  // References to entities matching the `matcher` are stored as a [Set]
  final Set<ObservableEntity> _entities = {};
  // References to group observers.
  final Set<GroupObserver> _observers = {};

  /// Matcher which is used to check the compliance of the entities.
  final EntityMatcher matcher;

  /// Adds observer to the group which will be notified on every mutating action.
  /// Observers are stored in a [Set].
  void addObserver(GroupObserver o) {
    _observers.add(o);
    __observerList = null;
  }

  /// Remove observer form the Group.
  void removeObserver(GroupObserver o) {
    _observers.remove(o);
    __observerList = null;
  }

  /// Lets user check if the group is empty.
  /// Does the check directly on the underlying data structure, without creation of unnecessary copies.
  bool get isEmpty => _entities.isEmpty;

  // Internal method called only by [EntityManager], to fill up a newly instantited group with exisitng matching entities.
  void _addEntity(ObservableEntity e) {
    _entities.add(e);
    for (var o in _observerList) {
      o.added(this, e);
    }
  }

  /// Group is an `EntityListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void destroyed(ObservableEntity e) {
    e.removeObserver(this);
  }

  /// Group is an `EntityListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    final isRelevantAdd =
        newC != null && matcher.containsType(newC.runtimeType);
    final isRelevantRemove =
        oldC != null && matcher.containsType(oldC.runtimeType);
    if ((isRelevantAdd || isRelevantRemove) == false) {
      return;
    }
    if (matcher.matches(e)) {
      if (_entities.add(e)) {
        __entities = null;
        for (var o in _observerList) {
          o.added(this, e);
        }
      } else {
        for (var o in _observerList) {
          o.updated(this, e);
        }
      }
    } else {
      if (_entities.remove(e)) {
        __entities = null;
        for (var o in _observerList) {
          o.removed(this, e);
        }
      }
    }
  }

  /// Creates a list of matching entities.
  /// This List contains the copy of references to the matching entities.
  /// As it is a copy, it is safe to use in a mutating loop.
  /// ### Example
  ///   for(var e in group.entities) {
  ///     e.destroy();
  ///   }
  /// As we call `destroy` on the entity `e` it will imideatly exit the group, but it is ok as we are iterating on list of entities and not on the group directly.
  List<ObservableEntity> get entities {
    return __entities ??= List.unmodifiable(_entities);
  }

  List<ObservableEntity> __entities;

  /// Helper method to perform destruction of all entities in the group.
  void destroyAllEntities() {
    for (var e in entities) {
      e.destroy();
    }
  }

  /// Groups are equal if their matchers are equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityGroup &&
          runtimeType == other.runtimeType &&
          matcher == other.matcher;

  /// Hash code of the group is equal to hash code of its matcher.
  @override
  int get hashCode => matcher.hashCode;

  // Caching the observer list, so that when observers are called they can safely remove themselves as observers
  List<GroupObserver> __observerList;
  List<GroupObserver> get _observerList {
    return __observerList ??= List.unmodifiable(_observers);
  }
}

typedef EntityManagerAction = void Function(EntityManager em);

/// Interface which you need to implement, if you want to observe changes on [EntityManager] instance
mixin EntityManagerObserver {
  void entityCreated(ObservableEntity e);
}

/// EntityManager is the central peace of entitas_ff. It can b eunderstood as a central managing data structure.
/// It manages the lifecycle of [Entity] instances and stores instances of [Group], which we use to access entities with certain qualities.
/// EntityManager is observable, see `addObserver`, `removeObserver`.
class EntityManager implements EntityObserver {
  /// sequential index of all created entities.
  var _currentEntityIndex = 0;

  /// holds all entities mapped by creation id.
  final Map<int, ObservableEntity> _entities = {};

  /// holds all groups mapped by entity matcher.
  final Map<EntityMatcher, EntityGroup> _groupsByMatcher = {};

  /// holds all unique entities mapped to unique component type
  final Map<Type, ObservableEntity> _uniqueEntities = {};

  /// holds observers
  final Set<EntityManagerObserver> _observers = {};

  /// holds buffered actions
  final List<EntityManagerAction> _bufferedActions = [];

  /// Adds a new buffered action
  void addBufferedAction(EntityManagerAction action) {
    _bufferedActions.add(action);
  }

  /// Clears all current buffered actions
  void clearBufferedActions() => _bufferedActions.clear();

  /// Calls all buffered actions and clears the list
  void flushActions() {
    for (var action in _bufferedActions) {
      action(this);
    }
    clearBufferedActions();
  }

  /// The only way how users can create new entities.
  /// ### Example
  ///   EntityManager em = EntityManager();
  ///   Entity e = em.createEntity();
  ///
  /// During creation the entity will receive a creation index id and it will receive all group as observers, becuase every entity might become part of the group at some point.
  /// At the end it will notify own observers that an eneitty was created.
  Entity createEntity() {
    final e = Entity._(_currentEntityIndex, this);
    _entities[_currentEntityIndex] = e;
    _currentEntityIndex++;
    for (final g in _groupsByMatcher.values) {
      e.addObserver(g);
    }
    for (final o in _observerList) {
      o.entityCreated(e);
    }
    return e;
  }

  /// Group is an `EntityListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void destroyed(ObservableEntity e) {
    _entities.remove(e.creationIndex);
  }

  /// Group is an `EntityListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (newC is UniqueComponent || oldC is UniqueComponent) {
      if (oldC != null && newC == null) {
        _uniqueEntities.remove(oldC.runtimeType);
      }
      if (newC != null) {
        final prevE = _uniqueEntities[newC.runtimeType];
        if (prevE != null) {
          assert(prevE == e, 'You added unique component to a second entity');
        } else {
          _uniqueEntities[newC.runtimeType] = e;
        }
      }
    }
  }

  /// Lets user set a unique component, which either exchanges a component on already existing entity, or creates a new entity and sets component on it.
  /// [Entity] which holds the unique component is returned
  Entity setUnique(UniqueComponent c) {
    var e = _uniqueEntities[c.runtimeType] ?? createEntity();
    return e += c;
  }

  void updateUnique<T extends UniqueComponent>(T Function(T old) updateTo) =>
      getUniqueEntity<T>()?.update<T>(updateTo);

  /// Sets a unique component on a provided [Entity].
  /// As there can be only one instance of a unique component type, it will first remove old unqiue component.
  /// ### Example
  ///   Entity e1 = entityManager.setUnique(Selected());
  ///   Entity e2 = entityManager.createEntity();
  ///   entityManager.setUniqueOnEntity(Selected(), e2);
  ///   assert(e1.has(Selected) == false);
  ///   assert(e2.has(Selected) == true);
  Entity setUniqueOnEntity(UniqueComponent c, Entity e) {
    var prevE = _uniqueEntities[c.runtimeType];
    if (prevE != null) {
      prevE -= c.runtimeType;
    }
    return e + c;
  }

  /// Removes unqiue component on an entity.
  /// If entity does not have any other components after removal, it is destroyed.
  void removeUnique<T extends UniqueComponent>() {
    final e = _uniqueEntities[T];
    if (e == null) {
      return;
    }
    e.remove<T>();
    if (e._components.isEmpty) {
      e.destroy();
    }
  }

  /// Returns the component instance or `null`.
  T getUnique<T extends UniqueComponent>() {
    return _uniqueEntities[T]?.get<T>();
  }

  /// Returns [Entity] instance which hold the unique component, or `null`.
  Entity getUniqueEntity<T extends UniqueComponent>() {
    return _uniqueEntities[T];
  }

  /// Convinience method to call `groupMatching` method.
  /// Creates an instance of [EntityMatcher]
  EntityGroup group(
      {List<Type> all, List<Type> any, List<Type> none, List<Type> maybe}) {
    final matcher = EntityMatcher(all: all, any: any, none: none, maybe: maybe);
    return groupMatching(matcher);
  }

  /// Returns a group backed by provided matcher.
  /// [EntityMatcher] instance should not be `null`.
  /// It is safe to call this method multiple times as the groups are cached and user will receive same cached instance.
  /// If a new group needs to be created it will be directly populated by existing matching entities.
  EntityGroup groupMatching(EntityMatcher matcher) {
    assert(matcher != null);
    var group = _groupsByMatcher[matcher];
    if (group != null) {
      return group;
    }
    group = EntityGroup._(matcher);
    for (var e in _entities.values) {
      e.addObserver(group);
      if (matcher.matches(e)) {
        group._addEntity(e);
      }
    }
    _groupsByMatcher[matcher] = group;
    return group;
  }

  /// Adds observer to the entity manager which will be notified on every mutating action.
  /// Observers are stored in a [Set].
  void addObserver(EntityManagerObserver o) {
    _observers.add(o);
    __observerList = null;
  }

  /// Removes observer.
  void removeObserver(EntityManagerObserver o) {
    _observers.remove(o);
    __observerList = null;
  }

  /// Return a List with reference copy of all entities.
  List<Entity> get entities => List.unmodifiable(_entities.values);

  // Caching the observer list, so that when observers are called they can safely remove themselves as observers
  List<EntityManagerObserver> __observerList = List(0);
  List<EntityManagerObserver> get _observerList {
    return __observerList ??= List.unmodifiable(_observers);
  }
}

/// Defines a function which given a [Component] instance can produce a key which is used in a [Map]
typedef KeyProducer<C extends Component, T> = T Function(C c);

/// A class which let users map entities against values of a component.
/// ### Example
///     var nameMap = EntityIndex<Name, String>(em, (name) => name.value );
///
/// An [EntityIndex] maps only one entity to a value component.
/// A situation, where multiple components are matching the same [EntityIndex] key is considered an error.
/// Please use [EntityMultiIndex] to cover such scenario.
class EntityIndex<C extends Component, T>
    implements EntityObserver, EntityManagerObserver {
  EntityIndex(EntityManager entityManager, this._keyProducer) {
    entityManager.addObserver(this);
    for (final e in entityManager.entities) {
      e.addObserver(this);
      if (e.has(C)) {
        exchanged(e, null, e.get<C>());
      }
    }
  }
  // holds entities entities mapped agauinst key
  final Map<T, Entity> _entities = {};
  // holds key producer instance
  final KeyProducer<C, T> _keyProducer;

  /// EntityIndex is an `EntityManagerListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void entityCreated(ObservableEntity e) {
    e.addObserver(this);
  }

  /// EntityIndex is an `EntityListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void destroyed(ObservableEntity e) {
    e.removeObserver(this);
  }

  /// EntityIndex is an `EntityListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (oldC is C || newC is C) {
      if (oldC != null) {
        _entities.remove(_keyProducer(oldC));
      }
      if (newC != null) {
        assert(_entities[_keyProducer(newC)] == null,
            'Multiple values for same key are prohibited in EntityIndex, please use EntityMultiIndex instead.');
        _entities[_keyProducer(newC)] = e;
      }
    }
  }

  /// Get an [Entity] instance or `null` based on provided key.
  Entity get(T key) {
    return _entities[key];
  }

  /// Get an [Entity] instance or `null` based on provided key.
  Entity operator [](T key) {
    return _entities[key];
  }
}

/// A class which let users map entities against values of a component.
/// ### Example
///     var ageMap = EntityMultiIndex<Age, int>(em, (name) => name.value);
///
/// It is different from [EntityIndex] in a way that it lets multiple entities match agains the same key.
class EntityMultiIndex<C extends Component, T>
    implements EntityObserver, EntityManagerObserver {
  EntityMultiIndex(EntityManager entityManager, this._keyProducer) {
    entityManager.addObserver(this);
    for (final e in entityManager.entities) {
      e.addObserver(this);
      if (e.has(C)) {
        exchanged(e, null, e.get<C>());
      }
    }
  }
  // holds list of entities mapped against key
  final Map<T, List<Entity>> _entities = {};
  // holds key producer
  final KeyProducer<C, T> _keyProducer;

  /// EntityMultiIndex is an `EntityManagerListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void entityCreated(ObservableEntity e) {
    e.addObserver(this);
  }

  /// EntityMultiIndex is an `EntityManagerListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void destroyed(ObservableEntity e) {
    e.removeObserver(this);
  }

  /// EntityMultiIndex is an `EntityManagerListener`, this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (oldC is C || newC is C) {
      if (oldC != null) {
        _entities[_keyProducer(oldC)]?.remove(e);
      }
      if (newC != null) {
        final list = _entities[_keyProducer(newC)] ?? []
          ..add(e);
        _entities[_keyProducer(newC)] = list;
      }
    }
  }

  /// Get a list of [Entity] instances or an empty list based on provided key.
  List<Entity> get(T key) {
    return List.unmodifiable(_entities[key] ?? []);
  }

  /// Get a list of [Entity] instances or an empty list based on provided key.
  List<Entity> operator [](T key) {
    return List.unmodifiable(_entities[key] ?? []);
  }
}
