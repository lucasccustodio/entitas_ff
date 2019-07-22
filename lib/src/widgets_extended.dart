import 'package:flutter/widgets.dart';
import 'package:entitas_ff/src/state.dart';
import 'package:entitas_ff/src/widgets.dart';

/// Defines a function which given an [Entity] instance, an [Animation] and [BuildContext] builds an animated widget.
typedef EntityBackedAnimatedBuilder<T>(
    Entity entity, Animation<T> animation, BuildContext context);

/// Modified [EntityObservingWidget] that also plays an animation
class EntityObservingAnimatedWidget<T> extends StatefulWidget {
  final EntityProvider provider;
  final EntityProvider fallback;
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
      this.shouldAnimate,
      this.fallback})
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
  void didUpdateWidget(EntityObservingAnimatedWidget<T> oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
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
    var shouldAnimate = widget.shouldAnimate?.call(newC) ?? true;

    if (!shouldAnimate) return;

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
  final EntityProvider fallback;
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
    this.fallback,
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
  void didUpdateWidget(EntityObservingAnimationsWidget oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimationsWidget");
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
    var shouldAnimate = widget.shouldAnimate?.call(newC) ?? true;

    if (!shouldAnimate) return;

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
  final EntityMapProvider fallback;
  final EntityMapBackedWidgetBuilder builder;

  const EntityMapObservingWidget(
      {Key key, this.provider, this.builder, this.fallback})
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
    if (_entityMap != null) {
      _entityMap.forEach((_, e) => e?.addObserver(this));
    } else {
      _entityMap = widget.fallback?.call(manager);
      if (_entityMap != null) {
        _entityMap.forEach((_, e) => e?.addObserver(this));
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(
        manager != null, "$widget is not a child of EntityMapObservingWidget");
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) {
      _entityMap.forEach((_, e) => e?.addObserver(this));
    } else {
      _entityMap = widget.fallback?.call(manager);
      if (_entityMap != null) {
        _entityMap.forEach((_, e) => e?.addObserver(this));
      }
    }
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
  final EntityMapProvider fallback;
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
      this.shouldAnimate,
      this.fallback})
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
    if (_entityMap != null) {
      _entityMap.forEach((_, e) => e?.addObserver(this));
    } else {
      _entityMap = widget.fallback?.call(manager);
      if (_entityMap != null) {
        _entityMap.forEach((_, e) => e?.addObserver(this));
      }
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(EntityMapObservingAnimatedWidget<T> oldWidget) {
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null,
        "$widget is not a child of EntityObservingAnimatedWidget");
    _entityMap?.forEach((_, e) => e?.removeObserver(this));
    _entityMap = widget.provider(manager);
    if (_entityMap != null) {
      _entityMap.forEach((_, e) => e?.addObserver(this));
    } else {
      _entityMap = widget.fallback?.call(manager);
      if (_entityMap != null) {
        _entityMap.forEach((_, e) => e?.addObserver(this));
      }
    }
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

    var shouldAnimate = widget.shouldAnimate?.call(entityName, newC) ?? true;

    if (!shouldAnimate) return;

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
  final EntityMapProvider fallback;
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
      this.shouldAnimate,
      this.fallback})
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
    if (_entityMap != null) {
      _entityMap.forEach((_, e) => e?.addObserver(this));
    } else {
      _entityMap = widget.fallback?.call(manager);
      if (_entityMap != null) {
        _entityMap.forEach((_, e) => e?.addObserver(this));
      }
    }
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
    } else {
      _entityMap = widget.fallback?.call(manager);
      if (_entityMap != null) {
        _entityMap.forEach((_, e) => e?.addObserver(this));
      }
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

    var shouldAnimate = widget.shouldAnimate?.call(entityName, newC) ?? true;

    if (!shouldAnimate) return;

    var reverse = widget.reverse?.call(entityName, newC) ?? false;

    if (reverse)
      _controller.reverse(from: 1.0);
    else
      _controller.forward(from: 0);
  }
}
