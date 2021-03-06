import 'package:orm/orm.dart';

class Hardware extends Entity {
  int _id;
  String _name;
  String _productor;
  
  Hardware ({int id, String name, String productor})
  : this._id = id,
    this._name = name,
    this._productor = productor;

  Hardware.fromMap (Map<String, dynamic> values)
  : this._id = values['id'],
    this._name = values['name'],
    this._productor = values['productor'];

  Hardware.fromMapSym (Map<Symbol, dynamic> values)
  : this._id = values[HardwareMeta.SYMBOL_ID],
  this._name = values[HardwareMeta.SYMBOL_NAME],
  this._productor = values[HardwareMeta.SYMBOL_PRODUCTOR];
  
  int get id => _id;
  String get name => _name;
  String get productor => _productor;
  HardwareMeta get entityMetadata => _meta;

  int get hashCode {
    int hash = 1;
    hash = 31 * hash + id.hashCode;
    hash = 31 * hash + name.hashCode;
    hash = 31 * hash + productor.hashCode;
    return hash;
  }
  
  bool operator == (Hardware hardware) => id == hardware.id &&
    name == hardware.name &&
    productor == hardware.productor;
  
  set id (int id) {
    if (HardwareMeta.PERSISTABLE_ID.validate(id)) {
      _id = id;
      if (entityMetadata.syncEnabled(this)) {
        _meta.onChange(this, HardwareMeta.FIELD_ID);
      }
    } else {
      throw new ArgumentError ('id is not valid');
    }
  }
  set name (String name) {
    if (HardwareMeta.PERSISTABLE_NAME.validate(name)) {
      _name = name;
      if (entityMetadata.syncEnabled(this)) {
        _meta.onChange(this, HardwareMeta.FIELD_NAME);
      }
    } else {
      throw new ArgumentError ('name is not valid');
    }
  }
  set productor (String productor) {
    if (HardwareMeta.PERSISTABLE_PRODUCTOR.validate(productor)) {
      _productor = productor;
      if (entityMetadata.syncEnabled(this)) {
        _meta.onChange(this, HardwareMeta.FIELD_PRODUCTOR);
      }
    } else {
      throw new ArgumentError ('productor is not valid');
    }
  }
  
  String toString () => '''{
    id: $id,
    name: $name,
    productor: $productor
  }''';
  
  static final HardwareMeta _meta = new HardwareMeta();
}

class HardwareMeta extends EntityMeta<Hardware> {

  String get idName => 'id';

  Symbol get idNameSym => SYMBOL_ID;

  String get entityName => ENTITY_NAME;

  Symbol get entityNameSym => ENTITY_NAME_SYM;

  List<String> get fields => FIELDS;

  List<Symbol> get fieldsSym => FIELDS_SYM;

  List asList (Hardware hardware) => [
    hardware.id,
    hardware.name,
    hardware.productor
  ];

  Map<String, dynamic> asMap (Hardware hardware) => <String, dynamic> {
    'id': hardware.id,
    'name': hardware.name,
    'productor': hardware.productor
  };
  
  Map<Symbol, dynamic> asMapSym (Hardware hardware) => <Symbol, dynamic> {
    SYMBOL_ID: hardware.id,
    SYMBOL_NAME: hardware.name,
    SYMBOL_PRODUCTOR: hardware.productor
  };
  
  String delete (Hardware hardware) => "DELETE FROM Hardware WHERE Hardware.$idName = '${get(hardware, idName)}';";
  
  dynamic get (Hardware hardware, String field) {
    switch (field) {
      case 'id':
        return hardware.id;
      case 'name':
        return hardware.name;
      case 'productor':
        return hardware.productor;
      default:
        throw new ArgumentError('Invalid field $field');
    }
  }
  
  String insert (Hardware hardware, {bool ignore: false}) {    
    var id = hardware.id;
    if (id is Entity) {
      id = id.entityMetadata.get(id, id.entityMetadata.idName);
    }    
    var name = hardware.name;
    if (name is Entity) {
      name = name.entityMetadata.get(name, name.entityMetadata.idName);
    }    
    var productor = hardware.productor;
    if (productor is Entity) {
      productor = productor.entityMetadata.get(productor, productor.entityMetadata.idName);
    }
    return "INSERT${ignore ? 'ignore ' : ' '}INTO Hardware (id, name, productor) VALUES (${id is num ? '${id}' : "'${id}'"}, ${name is num ? '${name}' : "'${name}'"}, ${productor is num ? '${productor}' : "'${productor}'"});";
  }
  
  String select (Hardware hardware, [List<String> fields]) {
    if (null == fields) {
      return 'SELECT * FROM Hardware WHERE Hardware.id = ${hardware.id} LIMIT 1';
    } else if (fields.isEmpty) {
      throw new ArgumentError('fields cannot be empty');
    }
    StringBuffer query = new StringBuffer('SELECT ');
    fields.forEach((field) => query.write('$field, '));
    return "${query.toString().substring(0, query.length - 2)} FROM Hardware WHERE Hardware.id = ${hardware.id} LIMIT 1;";
  }
  
  String selectAll (List<Hardware> hardwares, [List<String> fields]) {
    if (null == fields) {
      StringBuffer query = new StringBuffer('SELECT * FROM Hardware WHERE Hardware.id IN (');
      hardwares.forEach((hardware) => query.write("'${hardware.id}', "));
      return '${query.toString().substring(0, query.length - 2)}) LIMIT ${hardwares.length}';
    } else if (fields.isEmpty) {
      throw new ArgumentError('fields cannot be empty');
    }
    StringBuffer query = new StringBuffer('SELECT ');
    fields.forEach((field) => query.write('$field, '));
    query = new StringBuffer('${query.toString().substring(0, query.length - 2)} FROM Hardware WHERE Hardware.id IN (');
    hardwares.forEach((hardware) => query.write("${hardware.id is num ? hardware.id : "'${hardware.id}'"}, "));
    return '${query.toString().substring(0, query.length - 2)}) LIMIT ${hardwares.length};';
  }
  
  void set (Hardware hardware, String field, value) {
    switch (field) {
      case 'id':
        hardware.id = value;
        break;
      case 'name':
        hardware.name = value;
        break;
      case 'productor':
        hardware.productor = value;
        break;
      default:
        throw new ArgumentError('Invalid field $field');
    }
  }
  
  String update (Hardware hardware, List values, [List<String> fields]) {
    if (null == fields) {
      fields = HardwareMeta.FIELDS;
    }
    if (fields.isEmpty) {
      throw new ArgumentError('fields cannot be empty');
    }
    StringBuffer query = new StringBuffer('UPDATE Hardware SET ');
    fields.forEach((f) {
      var value = get(hardware, f);
      if (value is Entity) {
        value = value.entityMetadata.get(value, value.entityMetadata.idName);
      }
      query.write('$f = ${value is num ? value : "'$value'"}, ');
    });
    var id = get(hardware, idName);
    return "${query.toString().substring(0, query.length - 2)} WHERE Hardware.$idName = ${id is num ? id : "'$id'"};";
  }
  
  static const String ENTITY_NAME = 'Hardware';
  static const Symbol ENTITY_NAME_SYM = const Symbol ('Hardware');
  static const String FIELD_ID = 'id',
    FIELD_NAME = 'name',
    FIELD_PRODUCTOR = 'productor';
  static const List<String> FIELDS = const <String>[
    FIELD_ID,
    FIELD_NAME,
    FIELD_PRODUCTOR
  ];
  static const List<Symbol> FIELDS_SYM = const <Symbol>[
    SYMBOL_ID,
    SYMBOL_NAME,
    SYMBOL_PRODUCTOR
  ];
  static const String SQL_CREATE = 'CREATE TABLE Hardware (id INT NOT NULL, name VARCHAR(256) NOT NULL, productor VARCHAR(1500) NOT NULL, PRIMARY KEY(id));';
  static const Persistable PERSISTABLE_ID = const IntPersistable (),
    PERSISTABLE_NAME = const StringPersistable (),
    PERSISTABLE_PRODUCTOR = const StringPersistable (max: 1500);
  static const Symbol SYMBOL_ID = const Symbol('id'),
    SYMBOL_NAME = const Symbol('name'),
    SYMBOL_PRODUCTOR = const Symbol('productor');
}
