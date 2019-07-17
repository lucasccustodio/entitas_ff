import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'state.dart';
import 'behaviour.dart';

/// Widget which holds a reference to an [EntityManager] instance and can expose it to children.
/// If an instance of [RootSystem] is provided. It will be executed appropriately.
class EntityManagerProvider extends InheritedWidget {
  /// [EntityManager] instance provided on intialisation.
  final EntityManager entityManager;

  /// [RootSystem] instance provided on intialisation. Can be `null`.
  final RootSystem systems;

  EntityManagerProvider({
    Key key,
    @required EntityManager entityManager,
    this.systems,
    @required Widget child,
  })  : assert(child != null),
        assert(entityManager != null),
        entityManager = entityManager,
        super(
            key: key,
            child: systems != null
                ? _RootSystemWidget(child: child, systems: systems)
                : child);

  /// Returns [EntityManagerProvider] if it is part of your widget tree. Otherwise returns `null`.
  static EntityManagerProvider of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(EntityManagerProvider)
        as EntityManagerProvider;
  }

  @override
  bool updateShouldNotify(EntityManagerProvider oldWidget) =>
      oldWidget.entityManager != entityManager;
}

/// Internal widget which is used to tick along the instance of [RootSystem].
class _RootSystemWidget extends StatefulWidget {
  final Widget child;
  final RootSystem systems;
  const _RootSystemWidget(
      {Key key, @required this.child, @required this.systems})
      : assert(systems != null),
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
    super.initState();
    _ticker = createTicker(tick);
    _ticker.start();
    widget.systems.init();
  }

  @override
  void dispose() {
    _ticker.stop();
    widget.systems.exit();
    super.dispose();
  }

  tick(Duration elapsed) {
    widget.systems.execute();
    widget.systems.cleanup();
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

  /// Function which builds this widgets child, based on [Entity] and [BuildContext].
  final EntityBackedWidgetBuilder builder;

  const EntityObservingWidget(
      {Key key, @required this.provider, @required this.builder})
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
    if (_entity != null) _entity.addObserver(this);
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

/// Defines a function which given an [Entity] instance, an [Animation] and [BuildContext] builds an animated widget.
typedef EntityBackedAnimatedBuilder<T>(
    Entity entity, Animation<T> animation, BuildContext context);

/// Modified [EntityObservingWidget] that also plays an animation
class EntityObservingAnimatedWidget<T> extends StatefulWidget {
  final EntityProvider provider;
  final EntityBackedAnimatedBuilder<T> builder;
  final Tween<T> animation;
  final Curve curve;
  final Duration duration;

  /// Whether or not animate on the first build
  final bool startAnimating;

  /// The function provides the changed [Component] and the result tells whether or not play the animation;
  final bool Function(Component c) shouldAnimate;

  /// Builds upon the above function and also informs if the animation should play in reverse instead;
  final bool Function(Component c) reverse;

  const EntityObservingAnimatedWidget(
      {Key key,
      @required this.provider,
      @required this.builder,
      @required this.animation,
      @required this.startAnimating,
      this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      this.reverse,
      this.shouldAnimate})
      : super(key: key);

  @override
  _EntityObservingAnimatedWidgetState<T> createState() =>
      _EntityObservingAnimatedWidgetState<T>();
}

/// State class of [EntityObservingAnimatedWidget]
class _EntityObservingAnimatedWidgetState<T>
    extends State<EntityObservingAnimatedWidget<T>>
    with SingleTickerProviderStateMixin
    implements EntityObserver {
  Entity _entity;
  AnimationController _controller;
  Animation<T> _animation;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        setState(() {});
      });
    _animation = widget.animation
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.startAnimating) _controller.forward(from: 0);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    if (_entity != null) _entity.addObserver(this);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(EntityObservingAnimatedWidget<T> oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    if (_entity != null) _entity.addObserver(this);
    _animation = widget.animation
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.startAnimating) _controller.forward(from: 0);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, _animation, context);
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    var ignore = widget.shouldAnimate?.call(newC) ?? true;

    if (ignore) return;

    var reverse = widget.reverse?.call(newC) ?? false;

    if (reverse)
      _controller.reverse(from: 1.0);
    else
      _controller.forward(from: 0);
  }
}

/// Same as [EntityBackedAnimatedBuilder] but allows multiple animations
typedef EntityBackedAnimationsBuilder(
    Entity entity, Map<String, Animation> animations, BuildContext context);

/// Modified version of [EntityObservingAnimatedWidget] for multiple animations
class EntityObservingAnimationsWidget extends StatefulWidget {
  final EntityProvider provider;
  final EntityBackedAnimationsBuilder builder;
  final Map<String, Tween> animations;
  final Curve curve;
  final Duration duration;
  final bool startAnimating;
  final bool Function(Component c) shouldAnimate;
  final bool Function(Component c) reverse;

  const EntityObservingAnimationsWidget({
    Key key,
    @required this.provider,
    @required this.builder,
    @required this.animations,
    @required this.startAnimating,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 300),
    this.reverse,
    this.shouldAnimate,
  }) : super(key: key);

  @override
  _EntityObservingAnimationsWidgetState createState() =>
      _EntityObservingAnimationsWidgetState();
}

/// State class of [EntityObservingAnimationsWidget]
class _EntityObservingAnimationsWidgetState
    extends State<EntityObservingAnimationsWidget>
    with SingleTickerProviderStateMixin
    implements EntityObserver {
  Entity _entity;
  AnimationController _controller;
  Map<String, Animation> _animations;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        setState(() {});
      });
    _animations = widget.animations.map((name, anim) =>
        MapEntry<String, Animation>(
            name,
            anim.animate(
                CurvedAnimation(parent: _controller, curve: widget.curve))));
    if (widget.startAnimating) _controller.forward(from: 0);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimationsWidget");
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    if (_entity != null) _entity.addObserver(this);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(EntityObservingAnimationsWidget oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimationsWidget");
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    if (_entity != null) _entity.addObserver(this);
    _animations = widget.animations.map((name, anim) =>
        MapEntry<String, Animation>(
            name,
            anim.animate(
                CurvedAnimation(parent: _controller, curve: widget.curve))));
    if (widget.startAnimating) _controller.forward(from: 0);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, _animations, context);
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    var ignore = widget.shouldAnimate?.call(newC) ?? true;

    if (ignore) return;

    var reverse = widget.reverse?.call(newC) ?? false;

    if (reverse)
      _controller.reverse(from: 1.0);
    else
      _controller.forward(from: 0);
  }
}

/// Defines a function for building a Widget when any of the [Entity]'s from entityMap changes
typedef Widget EntityMapBackedWidgetBuilder(
    Map<String, Entity> entityMap, BuildContext context);

/// Given a [EntityManager] instance returns a map of [Entity]s to observe
typedef Map<String, Entity> EntityMapProvider(EntityManager em);

/// Modified version of [EntityObservingWidget] that can observe multiple [Entity]s
class EntityMapObservingWidget extends StatefulWidget {
  final EntityMapProvider provider;
  final EntityMapBackedWidgetBuilder builder;

  const EntityMapObservingWidget({Key key, this.provider, this.builder})
      : super(key: key);

  @override
  _EntityMapObservingWidgetState createState() =>
      _EntityMapObservingWidgetState();
}

/// State class of [EntityMapObservingWidget]
class _EntityMapObservingWidgetState extends State<EntityMapObservingWidget>
    implements EntityObserver {
  Map<String, Entity> _entityMap;

  @override
  void didUpdateWidget(EntityMapObservingWidget oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(
        manager != null, "$widget is not a child of EntityMapObservingWidget");
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) _entityMap.forEach((_, e) => e?.addObserver(this));
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(
        manager != null, "$widget is not a child of EntityMapObservingWidget");
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) _entityMap.forEach((_, e) => e?.addObserver(this));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entityMap, context);
  }

  @override
  void dispose() {
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    super.dispose();
  }

  @override
  destroyed(Entity e) {
    _update();
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    _update();
  }

  void _update() {
    setState(() {});
  }
}

/// Modified version of [EntityBackedAnimatedBuilder] for maps
typedef EntityMapBackedAnimatedBuilder<T>(
    Map<String, Entity> entity, Animation<T> animation, BuildContext context);

/// Modified version of [EntityObservingAnimatedWidget] for maps
class EntityMapObservingAnimatedWidget<T> extends StatefulWidget {
  final EntityMapProvider provider;
  final EntityMapBackedAnimatedBuilder<T> builder;

  /// [Animation] to play
  final Tween<T> animation;

  /// [Curve] to use on the animation, defaults to [Curves.linear]
  final Curve curve;

  /// Duration of the animation
  final Duration duration;

  /// If true, starts playing the animation when the widget is first built
  final bool startAnimating;

  /// Called when any of the observed [Entity]s changes a component, tells the [Entity]'s name and it's changed [Component] to determine if the animation should be played
  final bool Function(String name, Component c) shouldAnimate;

  /// Called when any of the observed [Entity]s changes a component, tells the [Entity]'s name and it's changed [Component] to determine if the animation should be played in reverse
  final bool Function(String name, Component c) reverse;

  const EntityMapObservingAnimatedWidget(
      {Key key,
      @required this.provider,
      @required this.builder,
      @required this.animation,
      @required this.startAnimating,
      this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      this.reverse,
      this.shouldAnimate})
      : super(key: key);

  @override
  _EntityMapObservingAnimatedWidgetState<T> createState() =>
      _EntityMapObservingAnimatedWidgetState<T>();
}

/// State class of [EntityMapObservingAnimatedWidget]
class _EntityMapObservingAnimatedWidgetState<T>
    extends State<EntityMapObservingAnimatedWidget<T>>
    with SingleTickerProviderStateMixin
    implements EntityObserver {
  Map<String, Entity> _entityMap;
  AnimationController _controller;
  Animation<T> _animation;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        setState(() {});
      });
    _animation = widget.animation
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.startAnimating) _controller.forward(from: 0);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) _entityMap.forEach((_, e) => e?.addObserver(this));
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(EntityMapObservingAnimatedWidget<T> oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) _entityMap.forEach((_, e) => e?.addObserver(this));
    _animation = widget.animation
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.startAnimating) _controller.forward(from: 0);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entityMap, _animation, context);
  }

  @override
  void dispose() {
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _controller.dispose();
    super.dispose();
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    var entityName;

    //Lookup for the entity ID on the provided map
    for (var entry in _entityMap.entries) {
      if (entry.value == e) entityName = entry.key;
    }

    var ignore = widget.shouldAnimate?.call(entityName, newC) ?? true;

    if (ignore) return;

    var reverse = widget.reverse?.call(entityName, newC) ?? false;

    if (reverse)
      _controller.reverse(from: 1.0);
    else
      _controller.forward(from: 0);
  }
}

/// Modified version of [EntityMapBackedAnimatedBuilder] for multiple animations
typedef EntityMapBackedAnimationsBuilder(Map<String, Entity> entity,
    Map<String, Animation> animation, BuildContext context);

/// Modified version of [EntityMapObservingAnimatedBuilder] for multiple animations
class EntityMapObservingAnimationsWidget extends StatefulWidget {
  final EntityMapProvider provider;
  final EntityMapBackedAnimationsBuilder builder;
  final Map<String, Tween> animations;
  final Curve curve;
  final Duration duration;
  final bool startAnimating;
  final bool Function(String name, Component c) shouldAnimate;
  final bool Function(String name, Component c) reverse;

  const EntityMapObservingAnimationsWidget(
      {Key key,
      @required this.provider,
      @required this.builder,
      @required this.animations,
      @required this.startAnimating,
      this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      this.reverse,
      this.shouldAnimate})
      : super(key: key);

  @override
  _EntityMapObservingAnimationsWidgetState createState() =>
      _EntityMapObservingAnimationsWidgetState();
}

/// State class of [EntityMapObservingAnimationsWidget]
class _EntityMapObservingAnimationsWidgetState<T>
    extends State<EntityMapObservingAnimationsWidget>
    with SingleTickerProviderStateMixin
    implements EntityObserver {
  Map<String, Entity> _entityMap;
  AnimationController _controller;
  Map<String, Animation> _animationsMap;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        setState(() {});
      });

    _animationsMap = widget.animations.map((name, anim) =>
        MapEntry<String, Animation>(
            name,
            anim.animate(
                CurvedAnimation(parent: _controller, curve: widget.curve))));
    if (widget.startAnimating) _controller.forward(from: 0);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) _entityMap.forEach((_, e) => e?.addObserver(this));
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(EntityMapObservingAnimationsWidget oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
    _animationsMap = widget.animations.map((name, anim) =>
        MapEntry<String, Animation>(
            name,
            anim.animate(
                CurvedAnimation(parent: _controller, curve: widget.curve))));
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) {
      _entityMap.forEach((_, e) => e?.addObserver(this));
    }
    if (widget.startAnimating) _controller.forward(from: 0);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entityMap, _animationsMap, context);
  }

  @override
  void dispose() {
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _controller.dispose();
    super.dispose();
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    var entityName;

    for (var entry in _entityMap.entries) {
      if (entry.value == e) entityName = entry.key;
    }

    var ignore = widget.shouldAnimate?.call(entityName, newC) ?? true;

    if (ignore) return;

    var reverse = widget.reverse?.call(entityName, newC) ?? false;

    if (reverse)
      _controller.reverse(from: 1.0);
    else
      _controller.forward(from: 0);
  }
}
