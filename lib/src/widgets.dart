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
    widget.system.onDestroy();
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
    SchedulerBinding.instance
        .addPostFrameCallback((_) => widget.system.onDestroy());
    super.dispose();
  }

  tick(Duration elapsed) {
    widget.system.execute();
    widget.system.cleanup();
  }
}

/// Defines a function which given an [EntityManager] instance returns a reference to an [Entity].
typedef Entity EntityProvider(EntityManager entityManager);

/// Callback for when a [Component] is added.
typedef bool ComponentAddedCallback(Component c);

/// Callback for when a [Component] is updated;
typedef bool ComponentUpdatedCallback(Component oldC, Component newC);

/// Callback for when [Component] is removed;
typedef bool ComponentRemovedCallback(Component c);

/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef Widget EntityWidgetBuilder(Entity e, BuildContext context);

/// Base class for [EntityObservingWidget]
abstract class EntityObservableWidget extends StatefulWidget {
  final EntityProvider provider = null;
}

mixin EntityWidget<T extends EntityObservableWidget> on State<T>
    implements EntityObserver {
  Entity _entity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _entity?.removeObserver(this);
    _entity = widget.provider(entityManager);
    if (_entity != null) _entity.addObserver(this);
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    super.dispose();
  }
}

/// Widget that rebuilds when its observing [Entity] add, update or remove a [Component].
class EntityObservingWidget extends EntityObservableWidget {
  final EntityProvider provider;
  final EntityWidgetBuilder builder;
  final ComponentAddedCallback rebuildAdded;
  final ComponentRemovedCallback rebuildRemoved;
  final ComponentUpdatedCallback rebuildUpdated;

  EntityObservingWidget(
      {Key key, @required this.provider, @required this.builder})
      : rebuildAdded = null,
        rebuildUpdated = null,
        rebuildRemoved = null;

  /// Variant that provides finer control over when to rebuild according to the result of each callback respectively.
  EntityObservingWidget.extended(
      {@required this.provider,
      @required this.builder,
      this.rebuildAdded,
      this.rebuildUpdated,
      this.rebuildRemoved});

  @override
  EntityObservingWidgetState createState() => EntityObservingWidgetState();
}

/// State class for [EntityObservingWidget]
class EntityObservingWidgetState extends State<EntityObservingWidget>
    with EntityWidget {
  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, context);
  }

  @override
  destroyed(Entity e) {
    _update();
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      var rebuildAdded = widget.rebuildAdded?.call(newC) ?? true;
      if (rebuildAdded) _update();
    } else if (oldC != null && newC != null) {
      var rebuildUpdated = widget.rebuildUpdated?.call(oldC, newC) ?? true;
      if (rebuildUpdated) _update();
    } else {
      var rebuildRemoved = widget.rebuildRemoved?.call(oldC) ?? true;
      if (rebuildRemoved) _update();
    }
  }

  _update() {
    if (mounted) setState(() {});
  }
}

/// Given an [Entity] reference, a [Map] of [Animation]s and a [BuildContext], produces a animated [Widget];
typedef Widget AnimatableEntityWidgetBuilder(
    Entity entity, Map<String, Animation> animations, BuildContext context);

enum EntityAnimation { none, forward, reverse }

/// Callback for when a [Component] is added.
typedef EntityAnimation AnimatableComponentAddedCallback(Component c);

/// Callback for when a [Component] is updated;
typedef EntityAnimation AnimatableComponentUpdatedCallback(
    Component oldC, Component newC);

/// Callback for when [Component] is removed;
typedef EntityAnimation AnimatableComponentRemovedCallback(Component c);

/// Base class for [AnimatableEntityObservingWidget]
abstract class AnimatableObservableWidget extends EntityObservableWidget {
  final AnimatableEntityWidgetBuilder builder = null;
  final AnimationController controller = null;
  final Map<String, Tween> tweens = null;
  final bool startAnimating = true;
  final Curve curve = Curves.linear;
  final Duration duration = const Duration(milliseconds: 300);
  final AnimatableComponentAddedCallback animateAdded = null;
  final AnimatableComponentRemovedCallback animateRemoved = null;
  final AnimatableComponentUpdatedCallback animateUpdated = null;
}

/// Mixin for [AnimatableEntityObservingWidget]
mixin AnimatableEntityWidget<T extends AnimatableObservableWidget> on State<T>
    implements
        EntityObserver,
        EntityWidget<T>,
        SingleTickerProviderStateMixin<T> {
  Map<String, Animation> _animations;
  AnimationController _controller;

  @override
  void didUpdateWidget(AnimatableObservableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimations();
  }

  void _updateAnimations() {
    _animations = widget.tweens.map((name, tween) =>
        MapEntry<String, Animation>(
            name,
            tween.animate(
                CurvedAnimation(parent: _controller, curve: widget.curve))));
    if (widget.startAnimating) _controller.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        setState(() {});
      });
    _updateAnimations();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, _animations, context);
  }

  void _updateButNotAnimate() {
    if (mounted) setState(() {});
  }

  void _playAnimation(EntityAnimation animation) {
    if (animation == EntityAnimation.none)
      return _updateButNotAnimate();
    else if (animation == EntityAnimation.forward)
      _controller.forward(from: 0);
    else
      _controller.reverse(from: 1);
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      var animate = widget.animateAdded?.call(newC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    } else if (oldC != null && newC != null) {
      var animate =
          widget.animateUpdated?.call(oldC, newC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    } else {
      var animate =
          widget.animateRemoved?.call(oldC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    }
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Widget that rebuilds when its [Entity] reference add, update or remove a [Component], that also can play one or more [Animation]s according to the result of animateAdded, animateUpdated and animateRemoved respectively.
class AnimatableEntityObservingWidget extends AnimatableObservableWidget {
  final Duration duration;
  final Curve curve;
  final Map<String, Tween> tweens;
  final bool startAnimating;
  final AnimationController controller;
  final AnimatableComponentAddedCallback animateAdded;
  final AnimatableComponentRemovedCallback animateRemoved;
  final AnimatableComponentUpdatedCallback animateUpdated;
  final EntityProvider provider;
  final AnimatableEntityWidgetBuilder builder;

  AnimatableEntityObservingWidget(
      {this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      @required this.tweens,
      this.startAnimating = true,
      this.animateAdded,
      this.animateRemoved,
      this.animateUpdated,
      this.controller,
      @required this.provider,
      @required this.builder});

  @override
  AnimatableEntityObservingWidgetState<AnimatableEntityObservingWidget>
      createState() => AnimatableEntityObservingWidgetState();
}

/// State class for [AnimatableEntityObservingWidget]
class AnimatableEntityObservingWidgetState<
        T extends AnimatableEntityObservingWidget> extends State<T>
    with
        EntityWidget<T>,
        AnimatableEntityWidget<T>,
        SingleTickerProviderStateMixin<T> {}

/// Defines a function which given a [EntityGroup] instance and [BuildContext] returns an instance of a [Widget].
typedef Widget GroupWidgetBuilder(EntityGroup group, BuildContext context);

abstract class GroupObservableWidget extends StatefulWidget {
  final EntityMatcher matcher;
  final GroupWidgetBuilder builder;

  const GroupObservableWidget(
      {Key key, @required this.matcher, @required this.builder})
      : super(key: key);
}

mixin GroupObservable<T extends GroupObservableWidget> on State<T>
    implements GroupObserver {
  EntityGroup _group;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null, "$widget is not a child of GroupObservingWidget");
    _group?.removeObserver(this);
    _group = manager.groupMatching(widget.matcher);
    _group.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_group, context);
  }

  _update() {
    if (mounted) setState(() {});
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
