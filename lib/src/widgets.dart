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
    widget.system.onCreate();
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
    Future.delayed(Duration.zero, () => widget.system.onDestroy());
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
typedef T EntityProvider<T extends ObservableEntity>(
    EntityManager entityManager);

/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef Widget EntityWidgetBuilder<T extends ObservableEntity>(
    T e, BuildContext context);

/// Base class for [EntityObservingWidget]
abstract class EntityObservableWidget<T extends ObservableEntity>
    extends StatefulWidget {
  final EntityProvider<T> provider = null;
}

mixin EntityWidget<T extends EntityObservableWidget<E>,
    E extends ObservableEntity> on State<T> implements EntityObserver {
  E _entity;

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
  void dispose() {
    _entity?.removeObserver(this);
    super.dispose();
  }
}

/// Widget that rebuilds when its [Entity] reference add, update or remove a [Component], that also can play one or more [Animation]s according to the result of animateAdded, animateUpdated and animateRemoved respectively.
class EntityObservingWidget<E extends ObservableEntity>
    extends EntityObservableWidget<E> {
  final EntityProvider<E> provider;
  final EntityWidgetBuilder<E> builder;

  EntityObservingWidget({Key key, this.provider, this.builder});

  @override
  EntityObservingWidgetState<EntityObservingWidget<E>, E> createState() =>
      EntityObservingWidgetState();
}

/// State class for [AnimatableEntityObservingWidget]
class EntityObservingWidgetState<T extends EntityObservingWidget<E>,
    E extends ObservableEntity> extends State<T> with EntityWidget {
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
    _update();
  }

  _update() {
    setState(() {});
  }
}

/// Given an [Entity] reference, a [Map] of [Animation]s and a [BuildContext], produces a animated [Widget];
typedef Widget AnimatableEntityWidgetBuilder<T extends ObservableEntity>(
    T entity, Map<String, Animation> animations, BuildContext context);

/// Base class for [AnimatableEntityObservingWidget]
abstract class AnimatableObservableWidget<T extends ObservableEntity>
    extends EntityObservableWidget<T> {
  final AnimatableEntityWidgetBuilder<T> builder = null;
  final Map<String, Tween> tweens = null;
  final bool startAnimating = true;
  final Curve curve = Curves.linear;
  final Duration duration = const Duration(milliseconds: 300);
  final double Function(Component addedC) animateAdded = null;
  final double Function(Component removedC) animateRemoved = null;
  final double Function(Component oldC, Component newC) animateUpdated = null;
}

/// Mixin for [AnimatableEntityObservingWidget]
mixin AnimatableEntityWidget<T extends AnimatableObservableWidget> on State<T>
    implements EntityObserver, SingleTickerProviderStateMixin<T> {
  Map<String, Animation> _animations;
  AnimationController _controller;

  @override
  void didUpdateWidget(AnimatableObservableWidget oldWidget) {
    updateAnimations();
    super.didUpdateWidget(oldWidget);
  }

  void updateAnimations() {
    _animations = widget.tweens.map((name, tween) =>
        MapEntry<String, Animation>(
            name,
            tween.animate(
                CurvedAnimation(parent: _controller, curve: widget.curve))));
    if (widget.startAnimating) _controller.forward(from: 0);
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        setState(() {});
      });
    updateAnimations();
    super.initState();
  }

  void playAnimation(double direction) {
    if (direction == 0)
      return;
    else if (direction > 0)
      _controller.forward(from: 0);
    else
      _controller.reverse(from: 1);
  }

  @override
  exchanged(ObservableEntity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      var animate = widget.animateAdded?.call(newC) ?? 1;

      playAnimation(animate);
    } else if (oldC != null && newC != null) {
      var animate = widget.animateUpdated?.call(oldC, newC) ?? 1;

      playAnimation(animate);
    } else {
      var animate = widget.animateRemoved?.call(oldC) ?? 1;

      playAnimation(animate);
    }
  }

  @override
  destroyed(ObservableEntity e) {
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Widget that rebuilds when its [Entity] reference add, update or remove a [Component], that also can play one or more [Animation]s according to the result of animateAdded, animateUpdated and animateRemoved respectively.
class AnimatableEntityObservingWidget<E extends ObservableEntity>
    extends AnimatableObservableWidget<E> {
  final Duration duration;
  final Curve curve;
  final Map<String, Tween> tweens;
  final bool startAnimating;
  final double Function(Component addedC) animateAdded;
  final double Function(Component removedC) animateRemoved;
  final double Function(Component oldC, Component newC) animateUpdated;
  final EntityProvider<E> provider;
  final AnimatableEntityWidgetBuilder<E> builder;

  AnimatableEntityObservingWidget(
      {this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      @required this.tweens,
      this.startAnimating = true,
      this.animateAdded,
      this.animateRemoved,
      this.animateUpdated,
      this.provider,
      this.builder});

  @override
  AnimatableEntityObservingWidgetState<AnimatableEntityObservingWidget<E>, E>
      createState() => AnimatableEntityObservingWidgetState();
}

/// State class for [AnimatableEntityObservingWidget]
class AnimatableEntityObservingWidgetState<
        T extends AnimatableEntityObservingWidget<E>,
        E extends ObservableEntity> extends State<T>
    with
        EntityWidget,
        AnimatableEntityWidget,
        SingleTickerProviderStateMixin<T> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, _animations, context);
  }
}

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
