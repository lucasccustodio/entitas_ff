import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

main(){
  test('update position', (){
    var entityManager = EntityManager();
    var entity = entityManager.createEntity();
    
    entity.set(Name("Entity"));

    expect(entity.get<Name>().value, "Entity");

    entity.update<Name>((oldName) => Name(oldName.value + " updated"));

    expect(entity.get<Name>().value, "Entity updated");
  });

  test("don't do anything if Entity hasn't the component", (){
    var entityManager = EntityManager();
    var entity = entityManager.createEntity();
    
    entity.update<Name>((oldName) => Name(oldName.value + " updated"));

    expect(entity.get<Name>(), null);
  });
}