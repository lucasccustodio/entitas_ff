import 'dart:math';

import 'package:entitas_ff/src/state.dart';
import 'package:entitas_ff/src/state_extended.dart';
import 'package:entitas_ff/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Defines a function which given an [Entity] (can be `null`), [Tween] and [BuildContext] returns a an instance of [Widget].
typedef Widget AnimatableEntityWidgetBuilder(
    Entity e, Map<String, Animation> animations, BuildContext context);

abstract class BaseAnimatableEntityObservableWidget<T> extends StatefulWidget {
  final EntityProvider provider;
  final AnimatableEntityWidgetBuilder builder;

  const BaseAnimatableEntityObservableWidget(
      {Key key, @required this.provider, @required this.builder})
      : super(key: key);
}

abstract class AnimatableEntityObservableWidget
    extends BaseAnimatableEntityObservableWidget {
  const AnimatableEntityObservableWidget(
      {Key key,
      @required EntityProvider provider,
      @required AnimatableEntityWidgetBuilder builder})
      : super(key: key, provider: provider, builder: builder);
}

mixin AnimatableEntityObservable<T extends AnimatableEntityObservableWidget>
    on State<AnimatableEntityObservingWidget>
    implements EntityObserver, TickerProvider {
  Entity _entity;
  Map<String, Animation> _animations;
  AnimationController _controller;
  Ticker _ticker;

  @override
  Ticker createTicker(onTick) {
    _ticker = Ticker(onTick);
    return _ticker;
  }

  @override
  void didChangeDependencies() {
    var entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _entity?.removeObserver(this);
    _entity = widget.provider(entityManager);
    if (_entity != null) _entity.addObserver(this);
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(AnimatableEntityObservingWidget oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, _animations, context);
  }

  void playAnimation(double direction) {
    if (direction == 0)
      return;
    else if (direction > 0)
      _controller.forward(from: 1);
    else
      _controller.reverse(from: 0);
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      var animate = widget.animateAdded?.call(newC) ?? 0;

      playAnimation(animate);
    } else if (oldC != null && newC != null) {
      var animate = widget.animateUpdated?.call(oldC, newC) ?? 0;

      playAnimation(animate);
    } else {
      var animate = widget.animateRemoved?.call(oldC) ?? 0;

      playAnimation(animate);
    }
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
}

class AnimatableEntityObservingWidget extends AnimatableEntityObservableWidget {
  final Duration duration;
  final Curve curve;
  final Map<String, Tween> tweens;
  final bool startAnimating;
  final double Function(Component addedC) animateAdded;
  final double Function(Component removedC) animateRemoved;
  final double Function(Component oldC, Component newC) animateUpdated;

  AnimatableEntityObservingWidget(
      {EntityProvider provider,
      this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      @required this.tweens,
      this.startAnimating = true,
      this.animateAdded,
      this.animateRemoved,
      this.animateUpdated,
      AnimatableEntityWidgetBuilder builder})
      : super(provider: provider, builder: builder);

  @override
  AnimatableEntityObservingWidgetState createState() =>
      AnimatableEntityObservingWidgetState();
}

class AnimatableEntityObservingWidgetState
    extends State<AnimatableEntityObservingWidget>
    with AnimatableEntityObservable {}

/// Defines a function which given an [EntityManager] instance returns a reference to an [Entity].
typedef EntityMap EntityMapProvider(EntityManager entityManager);

/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef Widget EntityMapWidgetBuilder(EntityMap e, BuildContext context);

abstract class BaseEntityMapObservableWidget extends StatefulWidget {
  final EntityMapProvider provider;
  final EntityMapWidgetBuilder builder;

  const BaseEntityMapObservableWidget(
      {Key key, @required this.provider, @required this.builder})
      : super(key: key);
}

abstract class EntityMapObservableWidget extends BaseEntityMapObservableWidget {
  const EntityMapObservableWidget(
      {Key key,
      @required EntityMapProvider provider,
      @required EntityMapWidgetBuilder builder})
      : super(key: key, provider: provider, builder: builder);
}

mixin EntityMapObservable<T extends EntityMapObservableWidget> on State<T>
    implements EntityObserver {
  EntityMap _entity;

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

class EntityMapObservingWidget extends EntityMapObservableWidget {
  EntityMapObservingWidget(
      {EntityMapProvider provider, EntityMapWidgetBuilder builder})
      : super(provider: provider, builder: builder);

  @override
  EntityMapObservingWidgetState createState() =>
      EntityMapObservingWidgetState();
}

class EntityMapObservingWidgetState extends State<EntityMapObservingWidget>
    with EntityMapObservable {}

typedef Widget AnimatableEntityMapWidgetBuilder(
    EntityMap e, Map<String, Animation> tweens, BuildContext context);

abstract class BaseAnimatableEntityMapObservableWidget extends StatefulWidget {
  final EntityMapProvider provider;
  final AnimatableEntityMapWidgetBuilder builder;

  const BaseAnimatableEntityMapObservableWidget(
      {Key key, @required this.provider, @required this.builder})
      : super(key: key);
}

abstract class AnimatableEntityMapObservableWidget
    extends BaseAnimatableEntityMapObservableWidget {
  const AnimatableEntityMapObservableWidget(
      {Key key,
      @required EntityMapProvider provider,
      @required AnimatableEntityMapWidgetBuilder builder})
      : super(key: key, provider: provider, builder: builder);
}

mixin AnimatableEntityMapObservable<
        T extends AnimatableEntityMapObservableWidget>
    on State<AnimatableEntityMapObservingWidget>
    implements EntityObserver, TickerProvider {
  EntityMap _entity;
  Map<String, Animation> _animations;
  AnimationController _controller;
  Ticker _ticker;

  @override
  Ticker createTicker(onTick) {
    _ticker = Ticker(onTick);
    return _ticker;
  }

  @override
  void didChangeDependencies() {
    var entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _entity?.removeObserver(this);
    _entity = widget.provider(entityManager);
    if (_entity != null) _entity.addObserver(this);
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(AnimatableEntityMapObservingWidget oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, _animations, context);
  }

  void playAnimation(double direction) {
    if (direction == 0)
      return;
    else if (direction > 0)
      _controller.forward(from: 1);
    else
      _controller.reverse(from: 0);
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      var animate = widget.animateAdded?.call(newC) ?? 0;

      playAnimation(animate);
    } else if (oldC != null && newC != null) {
      var animate = widget.animateUpdated?.call(oldC, newC) ?? 0;

      playAnimation(animate);
    } else {
      var animate = widget.animateRemoved?.call(oldC) ?? 0;

      playAnimation(animate);
    }
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
}

class AnimatableEntityMapObservingWidget
    extends AnimatableEntityMapObservableWidget {
  final Duration duration;
  final Curve curve;
  final Map<String, Tween> tweens;
  final bool startAnimating;
  final double Function(Component addedC) animateAdded;
  final double Function(Component removedC) animateRemoved;
  final double Function(Component oldC, Component newC) animateUpdated;

  AnimatableEntityMapObservingWidget(
      {EntityMapProvider provider,
      this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      @required this.tweens,
      this.startAnimating = true,
      this.animateAdded,
      this.animateRemoved,
      this.animateUpdated,
      AnimatableEntityMapWidgetBuilder builder})
      : super(provider: provider, builder: builder);

  @override
  AnimatableEntityMapObservingWidgetState createState() =>
      AnimatableEntityMapObservingWidgetState();
}

class AnimatableEntityMapObservingWidgetState
    extends State<AnimatableEntityMapObservingWidget>
    with AnimatableEntityMapObservable {}

/// Defines a function which given an [EntityManager] instance returns a reference to an [Entity].
typedef EntityList EntityListProvider(EntityManager entityManager);

/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef Widget EntityListWidgetBuilder(EntityList e, BuildContext context);

abstract class BaseEntityListObservableWidget extends StatefulWidget {
  final EntityListProvider provider;
  final EntityListWidgetBuilder builder;

  const BaseEntityListObservableWidget(
      {Key key, @required this.provider, @required this.builder})
      : super(key: key);
}

abstract class EntityListObservableWidget
    extends BaseEntityListObservableWidget {
  const EntityListObservableWidget(
      {Key key,
      @required EntityListProvider provider,
      @required EntityListWidgetBuilder builder})
      : super(key: key, provider: provider, builder: builder);
}

mixin EntityListObservable<T extends EntityListObservableWidget> on State<T>
    implements EntityObserver {
  EntityList _entity;

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

class EntityListObservingWidget extends EntityListObservableWidget {
  EntityListObservingWidget(
      {EntityListProvider provider, EntityListWidgetBuilder builder})
      : super(provider: provider, builder: builder);

  @override
  EntityListObservingWidgetState createState() =>
      EntityListObservingWidgetState();
}

class EntityListObservingWidgetState extends State<EntityListObservingWidget>
    with EntityListObservable {}

typedef Widget AnimatableEntityListWidgetBuilder(
    EntityList e, Map<String, Animation> animations, BuildContext context);

abstract class BaseAnimatableEntityListObservableWidget extends StatefulWidget {
  final EntityListProvider provider;
  final AnimatableEntityListWidgetBuilder builder;

  const BaseAnimatableEntityListObservableWidget(
      {Key key, @required this.provider, @required this.builder})
      : super(key: key);
}

abstract class AnimatableEntityListObservableWidget
    extends BaseAnimatableEntityListObservableWidget {
  const AnimatableEntityListObservableWidget(
      {Key key,
      @required EntityListProvider provider,
      @required AnimatableEntityListWidgetBuilder builder})
      : super(key: key, provider: provider, builder: builder);
}

mixin AnimatableEntityListObservable<
        T extends AnimatableEntityListObservableWidget>
    on State<AnimatableEntityListObservingWidget>
    implements EntityObserver, TickerProvider {
  EntityList _entity;
  Map<String, Animation> _animations;
  AnimationController _controller;
  Ticker _ticker;

  @override
  Ticker createTicker(onTick) {
    _ticker = Ticker(onTick);
    return _ticker;
  }

  @override
  void didChangeDependencies() {
    var entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _entity?.removeObserver(this);
    _entity = widget.provider(entityManager);
    if (_entity != null) _entity.addObserver(this);
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(AnimatableEntityListObservingWidget oldWidget) {
    updateAnimations();
    super.didUpdateWidget(oldWidget);
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

  void updateAnimations() {
    _animations = widget.tweens.map((name, tween) =>
        MapEntry<String, Animation>(
            name,
            tween.animate(
                CurvedAnimation(parent: _controller, curve: widget.curve))));
    if (widget.startAnimating) _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_entity, _animations, context);
  }

  void playAnimation(double direction) {
    if (direction == 0)
      return;
    else if (direction > 0)
      _controller.forward(from: 1);
    else
      _controller.reverse(from: 0);
  }

  @override
  exchanged(Entity e, Component oldC, Component newC) {
    if (oldC == null && newC != null) {
      var animate = widget.animateAdded?.call(newC) ?? 0;

      playAnimation(animate);
    } else if (oldC != null && newC != null) {
      var animate = widget.animateUpdated?.call(oldC, newC) ?? 0;

      playAnimation(animate);
    } else {
      var animate = widget.animateRemoved?.call(oldC) ?? 0;

      playAnimation(animate);
    }
  }

  @override
  destroyed(Entity e) {
    _controller.reset();
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
}

class AnimatableEntityListObservingWidget
    extends AnimatableEntityListObservableWidget {
  final Duration duration;
  final Curve curve;
  final Map<String, Tween> tweens;
  final bool startAnimating;
  final double Function(Component addedC) animateAdded;
  final double Function(Component removedC) animateRemoved;
  final double Function(Component oldC, Component newC) animateUpdated;

  AnimatableEntityListObservingWidget(
      {EntityListProvider provider,
      this.curve = Curves.linear,
      this.duration = const Duration(milliseconds: 300),
      @required this.tweens,
      this.startAnimating = true,
      this.animateAdded,
      this.animateRemoved,
      this.animateUpdated,
      AnimatableEntityListWidgetBuilder builder})
      : super(provider: provider, builder: builder);

  @override
  AnimatableEntityListObservingWidgetState createState() =>
      AnimatableEntityListObservingWidgetState();
}

class AnimatableEntityListObservingWidgetState
    extends State<AnimatableEntityListObservingWidget>
    with AnimatableEntityListObservable {}
