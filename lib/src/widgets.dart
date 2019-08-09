import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:entitas_ff/src/state.dart';
import 'package:entitas_ff/src/behaviour.dart';

/// Widget that can expose an [EntityManager] instance to its sub-tree.
/// By default it accepts an [RootSystem] instance and executes it appropriately, if present.
/// While EntityManagerProvider.feature requires an [FeatureSystem] instance and accepts two optional callbacks for the system lifecycle, see [FeatureSystem] to read about its usage.
class EntityManagerProvider extends InheritedWidget {
  /// Default constructor for [RootSystem]
  EntityManagerProvider({
    @required EntityManager entityManager,
    @required Widget child,
    Key key,
    RootSystem system,
  })  : assert(child != null),
        assert(entityManager != null),
        _entityManager = entityManager,
        super(
            key: key,
            child: system != null
                ? _RootSystemWidget(child: child, system: system)
                : child);

  /// Optional constructor for [FeatureSystem]
  EntityManagerProvider.feature({
    @required FeatureSystem system,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        _entityManager = null,
        super(
            key: key,
            child: _FeatureSystemWidget(child: child, system: system));

  final EntityManager _entityManager;

  static EntityManagerProvider of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(EntityManagerProvider);

  EntityManager get entityManager =>
      _entityManager ?? (child as _FeatureSystemWidget).entityManager;

  @override
  bool updateShouldNotify(EntityManagerProvider oldWidget) =>
      entityManager != oldWidget.entityManager;
}

/// Internal widget which is used to tick along the instance of [RootSystem].
class _RootSystemWidget extends StatefulWidget {
  const _RootSystemWidget(
      {@required this.child, @required this.system, Key key})
      : assert(system != null),
        super(key: key);

  final Widget child;
  final RootSystem system;

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
    _ticker = createTicker(tick)..start();
  }

  @override
  void dispose() {
    _ticker
      ..stop()
      ..dispose();
    widget.system.exit();
    widget.system.onDestroy();
    super.dispose();
  }

  void tick(Duration elapsed) {
    widget.system.execute();
    widget.system.cleanup();
  }
}

/// Internal widget which is used to tick along the instance of [FeatureSystem] and react to it's lifecycle.
class _FeatureSystemWidget extends StatefulWidget {
  const _FeatureSystemWidget(
      {@required this.child, @required this.system, Key key})
      : assert(system != null),
        assert(child != null),
        super(key: key);
  final Widget child;
  final FeatureSystem system;

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
    _ticker = createTicker(tick)..start();
  }

  @override
  void dispose() {
    _ticker
      ..stop()
      ..dispose();
    widget.system.exit();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => widget.system.onDestroy());
    super.dispose();
  }

  void tick(Duration elapsed) {
    widget.system.execute();
    widget.system.cleanup();
  }
}

/// Defines a function which given an [EntityManager] instance returns a reference to an [Entity].
typedef EntityProvider = Entity Function(EntityManager entityManager);

/// Callback for when a [Component] is added.
typedef ComponentAddedCallback = bool Function(Component c);

/// Callback for when a [Component] is updated;
typedef ComponentUpdatedCallback = bool Function(
    Component oldC, Component newC);

/// Callback for when [Component] is removed;
typedef ComponentRemovedCallback = bool Function(Component c);

/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef EntityWidgetBuilder = Widget Function(Entity e, BuildContext context);

/// Base class for [EntityObservingWidget]
abstract class EntityObservableWidget extends StatefulWidget {
  const EntityObservableWidget({Key key, this.provider}) : super(key: key);

  final EntityProvider provider;
}

mixin EntityWidget<T extends EntityObservableWidget> on State<T>
    implements EntityObserver {
  Entity _entity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _entity?.removeObserver(this);
    _entity = widget.provider(entityManager);
    if (_entity != null) {
      _entity.addObserver(this);
    }
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    super.dispose();
  }
}

/// Widget that rebuilds when its observing [Entity] add, update or remove a [Component].
class EntityObservingWidget extends EntityObservableWidget {
  /// Default constructor for EntityObservingWidget
  const EntityObservingWidget(
      {@required this.builder, EntityProvider provider, Key key})
      : rebuildAdded = null,
        rebuildUpdated = null,
        rebuildRemoved = null,
        super(key: key, provider: provider);

  /// Variant that provides finer control over when to rebuild according to the result of each callback respectively.
  const EntityObservingWidget.extended(
      {@required this.builder,
      EntityProvider provider,
      Key key,
      this.rebuildAdded,
      this.rebuildUpdated,
      this.rebuildRemoved})
      : super(key: key, provider: provider);

  final EntityWidgetBuilder builder;
  final ComponentAddedCallback rebuildAdded;
  final ComponentRemovedCallback rebuildRemoved;
  final ComponentUpdatedCallback rebuildUpdated;

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
  void destroyed(ObservableEntity e) {}

  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      final rebuildAdded = widget.rebuildAdded?.call(newC) ?? true;
      if (rebuildAdded) {
        _update();
      }
    } else if (oldC != null && newC != null) {
      final rebuildUpdated = widget.rebuildUpdated?.call(oldC, newC) ?? true;
      if (rebuildUpdated) {
        _update();
      }
    } else {
      final rebuildRemoved = widget.rebuildRemoved?.call(oldC) ?? true;
      if (rebuildRemoved) {
        _update();
      }
    }
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }
}

/// Given an [Entity] reference, a [Map] of [Animation]s and a [BuildContext], produces a animated [Widget];
typedef AnimatableEntityWidgetBuilder = Widget Function(
    Entity entity, Map<String, Animation> animations, BuildContext context);

enum EntityAnimation { none, forward, reverse, ignore }

/// Callback for when a [Component] is added.
typedef AnimatableComponentAddedCallback = EntityAnimation Function(
    Component c);

/// Callback for when a [Component] is updated;
typedef AnimatableComponentUpdatedCallback = EntityAnimation Function(
    Component oldC, Component newC);

/// Callback for when [Component] is removed;
typedef AnimatableComponentRemovedCallback = EntityAnimation Function(
    Component c);

/// Base class for [AnimatableEntityObservingWidget]
abstract class AnimatableObservableWidget extends EntityObservableWidget {
  const AnimatableObservableWidget(
      {Key key,
      EntityProvider provider,
      this.builder,
      this.controller,
      this.tweens,
      this.startAnimating,
      this.curve,
      this.duration,
      this.animateAdded,
      this.animateRemoved,
      this.animateUpdated,
      this.onAnimationEnd})
      : super(key: key, provider: provider);
  final AnimatableEntityWidgetBuilder builder;
  final AnimationController controller;
  final Map<String, Tween> tweens;
  final bool startAnimating;
  final Curve curve;
  final Duration duration;
  final AnimatableComponentAddedCallback animateAdded;
  final AnimatableComponentRemovedCallback animateRemoved;
  final AnimatableComponentUpdatedCallback animateUpdated;
  final void Function(bool reversed) onAnimationEnd;
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
    if (widget.startAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_update)
      ..addStatusListener(_updateStatus);
    _updateAnimations();
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onAnimationEnd?.call(false);
    } else if (status == AnimationStatus.dismissed) {
      widget.onAnimationEnd?.call(true);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_entity, _animations, context);

  void _playAnimation(EntityAnimation animation) {
    if (animation == EntityAnimation.ignore) {
      return;
    } else if (animation == EntityAnimation.none)
      return _update();
    else if (animation == EntityAnimation.forward)
      _controller.forward(from: 0);
    else
      _controller.reverse(from: 1);
  }

  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      final animate =
          widget.animateAdded?.call(newC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    } else if (oldC != null && newC != null) {
      final animate =
          widget.animateUpdated?.call(oldC, newC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    } else {
      final animate =
          widget.animateRemoved?.call(oldC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    }
  }

  @override
  void destroyed(ObservableEntity e) {
    _controller
      ..stop()
      ..removeListener(_update)
      ..removeStatusListener(_updateStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Widget that rebuilds when its [Entity] reference add, update or remove a [Component], that also can play one or more [Animation]s according to the result of animateAdded, animateUpdated and animateRemoved respectively.
class AnimatableEntityObservingWidget extends AnimatableObservableWidget {
  const AnimatableEntityObservingWidget(
      {@required EntityProvider provider,
      @required AnimatableEntityWidgetBuilder builder,
      @required Map<String, Tween> tweens,
      Key key,
      Curve curve = Curves.linear,
      Duration duration = const Duration(milliseconds: 300),
      bool startAnimating = true,
      AnimatableComponentAddedCallback animateAdded,
      AnimatableComponentRemovedCallback animateRemoved,
      AnimatableComponentUpdatedCallback animateUpdated,
      void Function(bool) onAnimationEnd,
      AnimationController controller})
      : super(
            key: key,
            provider: provider,
            builder: builder,
            curve: curve,
            duration: duration,
            tweens: tweens,
            startAnimating: startAnimating,
            animateAdded: animateAdded,
            animateRemoved: animateRemoved,
            animateUpdated: animateUpdated,
            onAnimationEnd: onAnimationEnd,
            controller: controller);

  @override
  AnimatableEntityObservingWidgetState<AnimatableEntityObservingWidget>
      createState() => AnimatableEntityObservingWidgetState();
}

/// State class for [AnimatableEntityObservingWidget]
class AnimatableEntityObservingWidgetState<
        T extends AnimatableEntityObservingWidget> extends State<T>
    with EntityWidget, AnimatableEntityWidget, SingleTickerProviderStateMixin {}

/// Defines a function which given a [EntityGroup] instance and [BuildContext] returns an instance of a [Widget].
typedef GroupWidgetBuilder = Widget Function(
    EntityGroup group, BuildContext context);

abstract class GroupObservableWidget extends StatefulWidget {
  const GroupObservableWidget(
      {@required this.matcher, @required this.builder, Key key})
      : super(key: key);

  final EntityMatcher matcher;
  final GroupWidgetBuilder builder;
}

mixin GroupObservable<T extends GroupObservableWidget> on State<T>
    implements GroupObserver {
  EntityGroup _group;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null, '$widget is not a child of GroupObservingWidget');
    _group?.removeObserver(this);
    _group = manager.groupMatching(widget.matcher)..addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_group, context);
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void added(EntityGroup group, Entity entity) {
    _update();
  }

  @override
  void removed(EntityGroup group, Entity entity) {
    _update();
  }

  @override
  void updated(EntityGroup group, Entity entity) {
    _update();
  }

  @override
  void dispose() {
    _group?.removeObserver(this);
    super.dispose();
  }
}

class GroupObservingWidget extends GroupObservableWidget {
  const GroupObservingWidget(
      {EntityMatcher matcher, GroupWidgetBuilder builder})
      : super(matcher: matcher, builder: builder);

  @override
  GroupObservingWidgetState createState() => GroupObservingWidgetState();
}

class GroupObservingWidgetState extends State<GroupObservingWidget>
    with GroupObservable {}
