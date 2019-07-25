# Changelog

## 0.2.2+3
- Fixed another bug related to the new callbacks where returning `null` would still trigger a rebuild/animate

## 0.2.2+2
- Fixed a bug related to the new callbacks where returning `null` would still trigger a rebuild/animate

## 0.2.2+1
- Added an extended constructor to both EntityObservingWidget and AnimatableEntityObservingWidget that exposes the callbacks to decide whether or not rebuild/animate.
- Bug-fixes, more tests and some cleanup.

## 0.2.2
- Got rid of all Entity\*ObservingWidget & AnimatableEntity\*ObservingWidget and refactored them to use generics instead which makes it alot easier to add more ObservableEntity variants wihtout needing to make more widgets.
- Added onCreate and onDestroyed lifecycle callbacks to RootSystem and ReactiveRootSystem.

## 0.2.1
- Refactored and improved all widgets, systems and tests

## 0.1.2
- Added FeatureSystem
- Improved documentation
- Added tests for basic widgets and FeatureSystem
- Fixed some bugs

## 0.1.1+3
- Finer control over the animation-related widgets

## 0.1.1+2
- Minor optimization by overring didChangeDependencies and didUpdateWidget
- Added EntityIndexObservingWidget, EntityIndexObservingAnimatedWidget, EntityIndexObservingAnimationsWidget and many other animation-related widgets

## 0.1.1+1
- Introduce the ExitSystem interface to call exit() when the application is terminated
- Add an update component method for Entity

## 0.1.1
### Introudce examples and small refactorings
- Introduce `destroyAllEntities` method onGroup
- Perfom small refactroings
- Introduce more sophisicated example apps

## 0.1.0
### Initital commit
- Implements state, behaviour and widgets, in the near future state and behavour should be migrated to exclusive entitas_dart lib as state and behaviour have no dependency to Flutter.
- Documentation needs more love
- Implements Flutter relevant examples - counter and shopping cart, should add example involving networking e.g. "github search"  similar to flutter_redux example
- Unit tests cover only state and behaviour, should add flutter tests for widgets