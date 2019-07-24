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
typedef Widget EntityWidgetBuilder(Entity e, BuildContext context);

abstract class BaseEntityObservableWidget extends StatefulWidget {
  final EntityProvider provider;
  final EntityWidgetBuilder builder;

  const BaseEntityObservableWidget(
      {Key key, @required this.provider, @required this.builder})
      : super(key: key);
}

abstract class EntityObservableWidget extends BaseEntityObservableWidget {
  const EntityObservableWidget(
      {Key key,
      @required EntityProvider provider,
      @required EntityWidgetBuilder builder})
      : super(key: key, provider: provider, builder: builder);
}

mixin EntityObservable<T extends EntityObservableWidget> on State<T>
    implements EntityObserver {
  Entity _entity;

  @override
  void didChangeDependencies() {
    var entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _entity?.removeObserver(this);
    _entity = widget.provider(entityManager);
    if (_entity != null) _entity.addObserver(this);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, context);
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    _update();
  }

  @override
  destroyed(Entity e) {
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

class EntityObservingWidget extends EntityObservableWidget {
  EntityObservingWidget({EntityProvider provider, EntityWidgetBuilder builder})
      : super(provider: provider, builder: builder);

  @override
  EntityObservingWidgetState createState() => EntityObservingWidgetState();
}

class EntityObservingWidgetState extends State<EntityObservingWidget>
    with EntityObservable {}

/// Defines a function which given a [EntityGroup] instance and [BuildContext] returns an instance of a [Widget].
typedef Widget GroupWidgetBuilder(EntityGroup group, BuildContext context);

abstract class BaseGroupObservableWidget extends StatefulWidget {
  final EntityMatcher matcher;
  final GroupWidgetBuilder builder;

  const BaseGroupObservableWidget(
      {Key key, @required this.matcher, @required this.builder})
      : super(key: key);
}

abstract class GroupObservableWidget extends BaseGroupObservableWidget {
  const GroupObservableWidget(
      {Key key,
      @required EntityMatcher matcher,
      @required GroupWidgetBuilder builder})
      : super(key: key, matcher: matcher, builder: builder);
}

mixin GroupObservable<T extends GroupObservableWidget> on State<T>
    implements GroupObserver {
  EntityGroup _group;

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
  Widget build(BuildContext context) {
    return widget.builder(_group, context);
  }

  _update() {
    setState(() {});
  }

  @override
  added(EntityGroup group, Entity entity) {
    _update();
  }

  @override
  removed(EntityGroup group, Entity entity) {
    _update();
  }

  @override
  updated(EntityGroup group, Entity entity) {
    _update();
  }

  @override
  void dispose() {
    _group?.removeObserver(this);
    super.dispose();
  }
}

class GroupObservingWidget extends GroupObservableWidget {
  GroupObservingWidget({EntityMatcher matcher, GroupWidgetBuilder builder})
      : super(matcher: matcher, builder: builder);

  @override
  GroupObservingWidgetState createState() => GroupObservingWidgetState();
}

class GroupObservingWidgetState extends State<GroupObservingWidget>
    with GroupObservable {}
