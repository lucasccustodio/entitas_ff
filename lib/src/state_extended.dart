import 'package:entitas_ff/src/state.dart';
import 'state.dart';

class EntityMap implements ObservableEntity {
  Map<String, Entity> _entityMap;

  EntityMap({Map<String, Entity> entityMap}) : _entityMap = entityMap;

  Entity operator [](String name) => entities[name];

  Map<String, Entity> get entities => Map.unmodifiable(_entityMap);

  @override
  addObserver(EntityObserver o) {
    _entityMap.forEach((_, e) => e?.addObserver(o));
  }

  @override
  removeObserver(EntityObserver o) {
    _entityMap.forEach((_, e) => e?.removeObserver(o));
  }
}

class EntityList implements ObservableEntity {
  List<Entity> _entityList;

  EntityList({List<Entity> entityList}) : _entityList = entityList;

  List<Entity> get entities => List.unmodifiable(_entityList);

  Entity operator [](int index) => entities[index];

  @override
  addObserver(EntityObserver o) {
    _entityList.forEach((e) => e?.addObserver(o));
  }

  @override
  removeObserver(EntityObserver o) {
    _entityList.forEach((e) => e?.removeObserver(o));
  }
}
