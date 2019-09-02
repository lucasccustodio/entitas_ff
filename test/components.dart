import 'package:entitas_ff/entitas_ff.dart';
import 'package:equatable/equatable.dart';

class CounterComponent = ComponentData<int> with UniqueMixin;

class Visible = TagComponent with ComponentMixin;

class Name = ComponentData<String> with ComponentMixin;

class Age = ComponentData<int> with ComponentMixin;

class IsSelected extends ComponentData<bool> with ComponentMixin {
  IsSelected({this.value = false});

  final bool value;
}

class Selected = TagComponent with UniqueMixin;

class Score = ComponentData<int> with UniqueMixin;

class Point2d extends Equatable {
  final int x;
  final int y;

  Point2d(this.x, this.y) : super([x, y]);
}

class Position extends ComponentData<Point2d> with ComponentMixin {
  Position(int x, int y) : super(Point2d(x, y));
}

class Velocity extends Position {
  Velocity(int x, int y) : super(x, y);
}
