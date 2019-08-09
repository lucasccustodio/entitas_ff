import 'package:entitas_ff/entitas_ff.dart';

class CounterComponent extends UniqueComponent {
  final int counter;

  CounterComponent(this.counter);
}

class Visible implements Component {}

class Name implements Component {
  final String value;

  Name(this.value);

  @override
  String toString() => value;
}

class Age implements Component {
  Age(this.value);

  final int value;
}

class IsSelected extends Component {
  IsSelected({this.value = false});

  final bool value;
}

class Selected implements UniqueComponent {}

class Score implements UniqueComponent {
  Score(this.value);

  final int value;
}

class Position implements Component {
  Position(this.x, this.y);

  final int x;
  final int y;
}

class Velocity implements Component {
  Velocity(this.x, this.y);

  final int x;
  final int y;
}
