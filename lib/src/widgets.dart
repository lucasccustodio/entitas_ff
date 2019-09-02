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

  // Returns a valid EntityManager instance in case of Feature
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

  // Start the ticker, call init systems and the lifecycle callback
  @override
  void initState() {
    super.initState();
    widget.system.onCreate();
    widget.system.init();
    _ticker = createTicker(tick)..start();
  }

  // Stop the ticker, call exit systems and the lifecycle callback
  @override
  void dispose() {
    _ticker
      ..stop()
      ..dispose();
    widget.system.exit();
    widget.system.onDestroy();
    super.dispose();
  }

  // call execute systems on every tick and then cleanup
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

  // Start the ticker, call init systems and the lifecycle callback
  @override
  void initState() {
    super.initState();
    widget.system.onCreate();
    widget.system.init();
    _ticker = createTicker(tick)..start();
  }

  // Stop the ticker, call exit systems and schedule the lifecycle callback
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

  // call execute systems on every tick and then cleanup
  void tick(Duration elapsed) {
    widget.system.execute();
    widget.system.cleanup();
  }
}

/// Defines a function which given an [EntityManager] instance returns a reference to an [Entity].
typedef EntityProvider = ObservableEntity Function(EntityManager entityManager);

/// Callback for when a [Component] is added.
typedef ComponentAddedCallback = bool Function(Component c);

/// Callback for when a [Component] is updated;
typedef ComponentUpdatedCallback = bool Function(
    Component oldC, Component newC);

/// Callback for when [Component] is removed;
typedef ComponentRemovedCallback = bool Function(Component c);

/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef EntityWidgetBuilder = Widget Function(
    ObservableEntity e, BuildContext context);

/// Base class for [EntityObservingWidget]
abstract class EntityObservableWidget extends StatefulWidget {
  const EntityObservableWidget(
      {@required this.provider, Key key, this.blacklist = const []})
      : super(key: key);

  final EntityProvider provider;
  final List<Type> blacklist;
}

// Mixin for a widget that observes an Entity
mixin EntityWidget<T extends EntityObservableWidget> on State<T>
    implements EntityObserver {
  ObservableEntity _entity;

  @override
  void destroyed(ObservableEntity e) {
    _update();
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

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

/// Widget that rebuilds when its observing [Entity] add, update or remove a [Component], if it's not in the blacklist.
class EntityObservingWidget extends EntityObservableWidget {
  /// Default constructor for EntityObservingWidget
  const EntityObservingWidget(
      {@required this.builder,
      @required EntityProvider provider,
      List<Type> blacklist = const [],
      Key key})
      : rebuildAdded = null,
        rebuildUpdated = null,
        rebuildRemoved = null,
        super(key: key, provider: provider, blacklist: blacklist);

  /// Variant that provides finer control over when to rebuild according to the result of each callback respectively.
  const EntityObservingWidget.extended(
      {@required this.builder,
      @required EntityProvider provider,
      List<Type> blacklist = const [],
      this.rebuildAdded,
      this.rebuildUpdated,
      this.rebuildRemoved,
      Key key})
      : super(key: key, provider: provider, blacklist: blacklist);

  final EntityWidgetBuilder builder;
  final ComponentAddedCallback rebuildAdded;
  final ComponentUpdatedCallback rebuildUpdated;
  final ComponentRemovedCallback rebuildRemoved;

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

  // Update the widget if the change passed all callbacks
  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      if (widget.blacklist.contains(newC.runtimeType)) return;

      if (widget.rebuildAdded?.call(newC) ?? true) _update();
    } else if (oldC != null && newC != null) {
      if (widget.blacklist.contains(newC.runtimeType)) return;

      if (widget.rebuildUpdated?.call(oldC, newC) ?? true) _update();
    } else {
      if (widget.blacklist.contains(oldC.runtimeType)) return;
      if (widget.rebuildRemoved?.call(oldC) ?? true) _update();
    }
  }
}

/// Given an [Entity] reference, a [Map] of [Animation]s and a [BuildContext], produces a animated [Widget];
typedef AnimatableEntityWidgetBuilder<E extends ObservableEntity> = Widget
    Function(E entity, Map<String, Animation> animations, BuildContext context);

/// None = Update without animating, ignore = Don't update at all
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
      {@required EntityProvider provider,
      Key key,
      List<Type> blacklist = const [],
      this.controller,
      this.tweens,
      this.startAnimating,
      this.curve,
      this.duration,
      this.onAnimationEnd})
      : super(key: key, provider: provider, blacklist: blacklist);
  final AnimationController controller;
  final Map<String, Tween> tweens;
  final bool startAnimating;
  final Curve curve;
  final Duration duration;
  final void Function(bool reversed) onAnimationEnd;
}

/// Mixin for [EntityWidget] that can be animated
mixin AnimatableEntityWidget<T extends AnimatableObservableWidget> on State<T>
    implements
        EntityObserver,
        EntityWidget<T>,
        SingleTickerProviderStateMixin<T> {
  Map<String, Animation> _animations;
  AnimationController _controller;

  // Widget configuration changed so update animations
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

  // Attach listeners and set up the animations
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_update)
      ..addStatusListener(_updateStatus);
    _updateAnimations();
  }

  // Handles callbacks for the animation
  void _updateStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onAnimationEnd?.call(false);
    } else if (status == AnimationStatus.dismissed) {
      widget.onAnimationEnd?.call(true);
    }
  }

  // Update the animation according to the criteria
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

  // Detach listeners
  @override
  void destroyed(ObservableEntity e) {
    _controller
      ..stop()
      ..removeListener(_update)
      ..removeStatusListener(_updateStatus);
  }

  // Remove listeners and dispose of controller
  @override
  void dispose() {
    _controller
      ..stop()
      ..removeListener(_update)
      ..removeStatusListener(_updateStatus)
      ..dispose();
    super.dispose();
  }
}

/// Widget that rebuilds when its [Entity] reference add, update or remove a [Component], that also can play one or more [Animation]s.
class AnimatableEntityObservingWidget extends AnimatableObservableWidget {
  const AnimatableEntityObservingWidget(
      {@required EntityProvider provider,
      @required this.builder,
      @required Map<String, Tween> tweens,
      List<Type> blacklist = const [],
      Key key,
      Curve curve = Curves.linear,
      Duration duration = const Duration(milliseconds: 300),
      bool startAnimating = true,
      void Function(bool) onAnimationEnd,
      AnimationController controller})
      : animateRemoved = null,
        animateAdded = null,
        animateUpdated = null,
        super(
            key: key,
            provider: provider,
            curve: curve,
            duration: duration,
            tweens: tweens,
            blacklist: blacklist,
            startAnimating: startAnimating,
            onAnimationEnd: onAnimationEnd,
            controller: controller);

  // Variant that provides finer control over when to animate due to changes
  const AnimatableEntityObservingWidget.extended(
      {@required EntityProvider provider,
      @required this.builder,
      @required Map<String, Tween> tweens,
      List<Type> blacklist = const [],
      Key key,
      Curve curve = Curves.linear,
      Duration duration = const Duration(milliseconds: 300),
      bool startAnimating = true,
      this.animateAdded,
      this.animateRemoved,
      this.animateUpdated,
      void Function(bool) onAnimationEnd,
      AnimationController controller})
      : super(
            key: key,
            provider: provider,
            curve: curve,
            duration: duration,
            tweens: tweens,
            blacklist: blacklist,
            startAnimating: startAnimating,
            onAnimationEnd: onAnimationEnd,
            controller: controller);

  final AnimatableEntityWidgetBuilder builder;
  final AnimatableComponentAddedCallback animateAdded;
  final AnimatableComponentRemovedCallback animateRemoved;
  final AnimatableComponentUpdatedCallback animateUpdated;

  @override
  AnimatableEntityObservingWidgetState<AnimatableEntityObservingWidget>
      createState() => AnimatableEntityObservingWidgetState();
}

/// State class for [AnimatableEntityObservingWidget]
class AnimatableEntityObservingWidgetState<
        T extends AnimatableEntityObservingWidget> extends State<T>
    with EntityWidget, AnimatableEntityWidget, SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) =>
      widget.builder(_entity, _animations, context);

  // Animate, rebuild or do nothing depending on the blacklist and callback results
  @override
  void exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      if (widget.blacklist.contains(newC.runtimeType)) return;

      final animate =
          widget.animateAdded?.call(newC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    } else if (oldC != null && newC != null) {
      if (widget.blacklist.contains(newC.runtimeType)) return;

      final animate =
          widget.animateUpdated?.call(oldC, newC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    } else if (oldC != null && newC == null) {
      if (widget.blacklist.contains(oldC.runtimeType)) return;

      final animate =
          widget.animateRemoved?.call(oldC) ?? EntityAnimation.forward;

      _playAnimation(animate);
    }
  }
}

/// Defines a function which given a [EntityGroup] instance and [BuildContext] returns an instance of a [Widget].
typedef GroupWidgetBuilder = Widget Function(
    EntityGroup group, BuildContext context);

/// Interface for a widget that observes changes in an EntityGroup
abstract class GroupObservableWidget extends StatefulWidget {
  const GroupObservableWidget(
      {@required this.matcher, @required this.builder, Key key})
      : super(key: key);

  final EntityMatcher matcher;
  final GroupWidgetBuilder builder;
}

/// Mixing for widget that observes an [EntityGroup]
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
  void added(EntityGroup group, ObservableEntity entity) {
    _update();
  }

  @override
  void removed(EntityGroup group, ObservableEntity entity) {
    _update();
  }

  @override
  void updated(EntityGroup group, ObservableEntity entity) {
    _update();
  }

  @override
  void dispose() {
    _group?.removeObserver(this);
    super.dispose();
  }
}

/// Widget that observes changes in a EntityGroup
class GroupObservingWidget extends GroupObservableWidget {
  const GroupObservingWidget(
      {@required EntityMatcher matcher, @required GroupWidgetBuilder builder})
      : super(matcher: matcher, builder: builder);

  @override
  GroupObservingWidgetState createState() => GroupObservingWidgetState();
}

/// State class for [GroupObservingWidget]
class GroupObservingWidgetState extends State<GroupObservingWidget>
    with GroupObservable {}
