# Changelog

## 0.1.1+2
- Minor optimization by overring didChangeDependencies and didUpdateWidget
- Added EntityMapObservingWidget, EntityMapObservingAnimatedWidget, EntityMapObservingAnimationsWidget and many other animation-related widgets

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