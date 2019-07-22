import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:entitas_ff/src/state.dart';
import 'package:entitas_ff/src/behaviour.dart';

/// Widget that can expose an [EntityManager] instance to its sub-tree.
/// By default it accepts an [RootSystem] instance and executes it appropriately, if present.
/// While EntityManagerProvider.feature requires an [FeatureSystem] instance and accepts two optional callbacks for the system lifecycle, see [FeatureSystem] to read about its usage.
class EntityManagerProvider extends InheritedWidget {
  final EntityManager _entityManager;
  final Widget child;

  /// Default constructor for [RootSystem]
  EntityManagerProvider({
    Key key,
    @required EntityManager entityManager,
    RootSystem system,
    @required Widget child,
  })  : assert(child != null),
        assert(entityManager != null),
        _entityManager = entityManager,
        child = system != null
            ? _RootSystemWidget(child: child, system: system)
            : child,
        super(key: key);

  /// Optional constructor for [FeatureSystem]
  EntityManagerProvider.feature({
    Key key,
    @required FeatureSystem system,
    @required Widget child,
  })  : assert(child != null),
        _entityManager = null,
        child = _FeatureSystemWidget(child: child, system: system),
        super(key: key);

  static EntityManagerProvider of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(EntityManagerProvider)
          as EntityManagerProvider);

  EntityManager get entityManager =>
      _entityManager ?? (child as _FeatureSystemWidget).entityManager;

  @override
  bool updateShouldNotify(EntityManagerProvider oldWidget) =>
      entityManager != oldWidget.entityManager;
}

/// Internal widget which is used to tick along the instance of [RootSystem].
class _RootSystemWidget extends StatefulWidget {
  final Widget child;
  final RootSystem system;
  const _RootSystemWidget(
      {Key key, @required this.child, @required this.system})
      : assert(system != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _RootSystemWidgetState();
}

/// State class of internal widget [_RootSystemWidget]
class _RootSystemWidgetState extends State<_RootSystemWidget>
    with SingleTickerProviderStateMixin {
  Ticker _ticker;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    widget.system.init();
    _ticker = createTicker(tick);
    _ticker.start();
    super.initState();
  }

  @override
  void dispose() {
    _ticker.stop();
    _ticker.dispose();
    widget.system.exit();
    super.dispose();
  }

  tick(Duration elapsed) {
    widget.system.execute();
    widget.system.cleanup();
  }
}

/// Internal widget which is used to tick along the instance of [FeatureSystem] and react to it's lifecycle.
class _FeatureSystemWidget extends StatefulWidget {
  final Widget child;
  final FeatureSystem system;

  const _FeatureSystemWidget(
      {Key key, @required this.child, @required this.system})
      : assert(system != null),
        assert(child != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _FeatureSystemWidgetState();

  EntityManager get entityManager => system.entityManager;
}

/// State class of internal widget [_FeatureSystemWidget]
class _FeatureSystemWidgetState extends State<_FeatureSystemWidget>
    with SingleTickerProviderStateMixin {
  Ticker _ticker;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    widget.system.onCreate();
    widget.system.init();
    _ticker = createTicker(tick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.stop();
    _ticker.dispose();
    widget.system.exit();
    Future.delayed(Duration.zero, () => widget.system.onDestroy());
    super.dispose();
  }

  tick(Duration elapsed) {
    widget.system.execute();
    widget.system.cleanup();
  }
}

/// Defines a function which given an [EntityManager] instance returns a reference to an [Entity].
typedef Entity EntityProvider(EntityManager entityManager);

/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef Widget EntityBackedWidgetBuilder(Entity e, BuildContext context);

/// Widget which observes an entity and rebuilds it's child when the entity has changed.
class EntityObservingWidget extends StatefulWidget {
  /// Function which returns an entity the widget should observe.
  final EntityProvider provider;

  /// If provider returns null, use this to initialize the entity to observe.
  final EntityProvider fallback;

  /// Function which builds this widgets child, based on [Entity] and [BuildContext].
  final EntityBackedWidgetBuilder builder;

  const EntityObservingWidget(
      {Key key, @required this.provider, @required this.builder, this.fallback})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => EntityObservingWidgetState();
}

/// State class for [EntityObservingWidget].
class EntityObservingWidgetState extends State<EntityObservingWidget>
    implements EntityObserver {
  // holds reference to entity under observation
  Entity _entity;

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null, "$widget is not a child of EntityObservingWidget");
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    if (_entity != null) {
      _entity.addObserver(this);
    } else {
      _entity = widget.fallback?.call(manager);
      if (_entity != null) {
        _entity.addObserver(this);
      }
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(EntityObservingWidget oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null, "$widget is not a child of EntityObservingWidget");
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    if (_entity != null) _entity.addObserver(this);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, context);
  }

  /// Implementation of [EntityObserver]
  @override
  destroyed(Entity e) {
    _update();
  }

  /// Implementation of [EntityObserver]
  @override
  exchanged(Entity e, Component oldC, Component newC) {
    _update();
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    super.dispose();
  }
}

/// Defines a function which given a [Group] instance and [BuildContext] returns an instance of a [Widget].
typedef Widget GroupBackedWidgetBuilder(Group group, BuildContext context);

/// Widget which observes a group and rebuilds it's child when the group has changed.
class GroupObservingWidget extends StatefulWidget {
  /// holds reference to provided matcher
  final EntityMatcher matcher;

  /// holds reference to function which builds the child [Widget]
  final GroupBackedWidgetBuilder builder;

  const GroupObservingWidget(
      {Key key, @required this.matcher, @required this.builder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => GroupObservingWidgetState();
}

class GroupObservingWidgetState extends State<GroupObservingWidget>
    implements GroupObserver {
  // holds reference to group under observation
  Group _group;

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null, "$widget is not a child of GroupObservingWidget");
    _group?.removeObserver(this);
    _group = manager.groupMatching(widget.matcher);
    _group.addObserver(this);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(GroupObservingWidget oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null, "$widget is not a child of GroupObservingWidget");
    _group?.removeObserver(this);
    _group = manager.groupMatching(widget.matcher);
    _group.addObserver(this);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_group, context);
  }

  @override
  void dispose() {
    _group.removeObserver(this);
    super.dispose();
  }

  /// Implementation of [GroupObserver]
  @override
  added(Group group, Entity entity) {
    _update();
  }

  /// Implementation of [GroupObserver]
  @override
  removed(Group group, Entity entity) {
    _update();
  }

  /// Implementation of [GroupObserver]
  @override
  updated(Group group, Entity entity) {
    _update();
  }

  _update() {
    setState(() {});
  }
}
