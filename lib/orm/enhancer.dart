part of orm;

class EnhancerEntity {
  final StringBuffer _buffer = new StringBuffer ();
  final String entityMetaName;
  final String entityName;
  final String entityNamelc;
  final ExtendsClause extendsClause;
  final bool hasParent;
  final bool isAbstract;
  
  final List<ImportDirective> imports = <ImportDirective>[];
  final List<Member> members = <Member>[];
  final List<MethodDeclaration> methods = <MethodDeclaration>[];
  
  Iterable<EnhancerEntity> entities;
  Iterable<String> files;
  Member id;
  EnhancerEntity superclass;
  
  EnhancerEntity(ClassDeclaration cd)
      : entityMetaName = '${cd.name.name}Meta',
      entityName = cd.name.name,
      entityNamelc = cd.name.name.toLowerCase(),
      extendsClause = cd.extendsClause,
      hasParent = null != cd.extendsClause,
      isAbstract = null != cd.abstractKeyword;
      
  Member get identifier => null == id ? 
      (hasParent ? superclass.identifier : null) : id;
  
  Map<String, String> _annotationArguments (Annotation a) {
    Map<String, String> args = <String, String> {};
    a.arguments.arguments.forEach((arg) {
      String argument = arg.toString();
      int pos = argument.indexOf(':');
      args[argument.substring(0, pos)] = argument.substring(pos + 2);
    });
    return args;
  }
      
  String _asArray () {
    _buffer
        ..clear()
        ..write('List asList ($entityName $entityNamelc) => [');
    _inheritanceChain().forEach((entity) =>
      entity.members.forEach((member) =>
          _buffer.write('\n    $entityNamelc.${member.vdname},')));
    return '${_buffer.toString().substring(0, _buffer.length - 1)}\n  ];';
  }
  
  String _asMap () {
    _buffer
        ..clear()
        ..write('Map<String, dynamic> asMap ($entityName $entityNamelc) => <String, dynamic> {');
    _inheritanceChain().forEach((entity) => entity.members.forEach((member) {
      String vdname = member.vdname;
      _buffer.write("\n    '${member.vdname}': $entityNamelc.${member.vdname},");
    }));
    return '${_buffer.toString().substring(0, _buffer.length - 1)}\n  };';
  }
  
  String _asMapSym () {
    _buffer
        ..clear()
        ..write('Map<Symbol, dynamic> asMapSym ($entityName $entityNamelc) => <Symbol, dynamic> {');
    _inheritanceChain().forEach((entity) {
      if (this == entity) {
        entity.members.forEach((member) =>
          _buffer.write("\n    SYMBOL_${member.vdnameuc}: $entityNamelc.${member.vdname},")
        );
      } else {
        entity.members.forEach((member) => 
            _buffer.write('\n    ${entity.entityMetaName}.SYMBOL_${member.vdnameuc}: $entityNamelc.${member.vdname},'));
      }
    });
    return '${_buffer.toString().substring(0, _buffer.length - 1)}\n  };';
  }
  
  String _constructors() {
    //Standard constructor
    _buffer..clear()
      ..write('$entityName ({');
    _inheritanceChain().forEach((entity) {
      entity.members.forEach((member) => 
          _buffer.write('${member.typeName} ${member.vdname}, '));
    });
    String tmp = _buffer.toString().substring(0, _buffer.length - 2);
    _buffer..clear()..write('$tmp})\n  : ');
    _inheritanceChain().forEach((entity) {
      if (this == entity) {
        if (1 !=_inheritanceChain().length) {
          tmp = '${_buffer.toString().substring(0, _buffer.length - 2)}),\n  ';
          _buffer..clear()..write(tmp);
        }
        members.forEach((member) 
            => _buffer.write('this._${member.vdname} = ${member.vdname},\n    '));
        tmp = '${_buffer.toString().substring(0, _buffer.length - 6)};';
        _buffer..clear()..write('$tmp\n\n  ');
      } else {
        if (_inheritanceChain().first == entity) {
          _buffer.write('super(');
        }
        entity.members.forEach((member) => 
            _buffer.write('${member.vdname}: ${member.vdname},\n    '));
        tmp = '${_buffer.toString().substring(0, _buffer.length - 6)}, ';
        _buffer..clear()..write(tmp);
      }
    });
    //String map constructor
    _buffer.write('$entityName.fromMap (Map<String, dynamic> values)\n  : ');
    _inheritanceChain().forEach((entity) {
      if (this == entity) {
        if (1 !=_inheritanceChain().length) {
          tmp = '${_buffer.toString().substring(0, _buffer.length - 2)}),\n  ';
          _buffer..clear()..write(tmp);
        }
        members.forEach((member) 
            => _buffer.write("this._${member.vdname} = values['${member.vdname}'],\n    "));
        tmp = '${_buffer.toString().substring(0, _buffer.length - 6)};';
        _buffer..clear()..write('$tmp\n\n  ');
      } else {
        if (_inheritanceChain().first == entity) {
          _buffer.write('super(');
        }
        entity.members.forEach((member) 
            => _buffer.write("${member.vdname}: values['${member.vdname}'],\n    "));
        tmp = '${_buffer.toString().substring(0, _buffer.length - 6)}, ';
        _buffer..clear()..write(tmp);
      }
    });
    //Symbol map constructor
    _buffer.write('$entityName.fromMapSym (Map<Symbol, dynamic> values)\n  : ');
    _inheritanceChain().forEach((entity) {
      if (this == entity) {
        if (1 !=_inheritanceChain().length) {
          tmp = '${_buffer.toString().substring(0, _buffer.length - 4)}),\n  ';
          _buffer..clear()..write(tmp);
        }
        members.forEach((member) 
            => _buffer.write("this._${member.vdname} = values[$entityMetaName.SYMBOL_${member.vdnameuc}],\n  "));
      } else {
        if (_inheritanceChain().first == entity) {
          _buffer.write('super(');
        }
        entity.members.forEach((member) 
            => _buffer.write('${member.vdname}: values[${entity.entityMetaName}.SYMBOL_${member.vdnameuc}],\n    '));
        tmp = '${_buffer.toString().substring(0, _buffer.length - 6)},\n  ';
        _buffer..clear()..write(tmp);
      }
    });
    return '${_buffer.toString().substring(0, _buffer.length - 4)};';
  }
  
  String _delete () => 'String delete ($entityName $entityNamelc) => "DELETE FROM $entityName WHERE $entityName.\$idName = \'\${get($entityNamelc, idName)}\';";';
  
  String _equals () {
    _buffer..clear()..write('bool operator == ($entityName $entityNamelc) => ');
    _inheritanceChain().forEach((entity) =>
        entity.members.forEach((member) =>
            _buffer.write('${member.vdname} == $entityNamelc.${member.vdname} &&\n    ')));
    return '${_buffer.toString().substring(0, _buffer.length - 8)};';
  }
  
  String _fields () {
    _buffer
        ..clear()
        ..write('static const String ');
    members.forEach((member) =>
        _buffer.write("FIELD_${member.vdnameuc} = '${member.vdname}',\n    "));
    return '${_buffer.toString().substring(0, _buffer.length - 6)};';
  }
  
  String _fieldsList () {
    _buffer
        ..clear()
        ..write('static const List<String> FIELDS = const <String>[');
    _inheritanceChain().forEach((entity) {
      if (this == entity) {
        members.forEach((member) =>
            _buffer.write("\n    FIELD_${member.vdnameuc},"));
      } else {
        entity.members.forEach((member) => 
            _buffer.write("\n    ${entity.entityMetaName}.FIELD_${member.vdnameuc},"));
      }
    });
    return '${_buffer.toString().substring(0, _buffer.length - 1)}\n  ];';
  }
  
  String _fieldsListSym () {
    _buffer
        ..clear()
        ..write('static const List<Symbol> FIELDS_SYM = const <Symbol>[');
    if (hasParent) {
      superclass.members.forEach((member) =>
          _buffer.write("\n    ${superclass.entityMetaName}.SYMBOL_${member.vdnameuc},"));
    }
    members.forEach((member) =>
        _buffer.write("\n    SYMBOL_${member.vdnameuc},"));
    return '${_buffer.toString().substring(0, _buffer.length - 1)}\n  ];';
  }
  
  String _get () {
    _buffer
        ..clear()
        ..write('dynamic get ($entityName $entityNamelc, String field) {\n    switch (field) {\n');
    List<Member> ms = <Member>[];
    members.forEach((member) => _buffer.write("      case '${member.vdname}':\n        return $entityNamelc.${member.vdname};\n"));
    return '''$_buffer      default:
        ${hasParent ? 'return super.get($entityNamelc, field);' : "throw new ArgumentError('Invalid field \$field');"}
    }
  }''';
  }
  
  String _getters () {
    _buffer.clear();
    members.forEach((member) => _buffer.write('${member.asGetter()}\n  '));
    return '${_buffer.toString().substring(0, _buffer.length - 3)}';
  }
  
  String _hashCode () {
    _buffer
        ..clear()
        ..write('''int get hashCode {
    int hash = ${hasParent ? 'super.hashCode' : '1'};''');
    members.forEach((member) => _buffer.write('\n    hash = 31 * hash + ${member.vdname}.hashCode;'));
    return '${_buffer.toString()}\n    return hash;\n  }';
  }
  
  String _imports () {
    _buffer.clear();
    List<String> parents = <String>[];
    _inheritanceChain().forEach((entity) {
      if (this != entity) {
        files.forEach((file) {
          if (file.contains(entity.entityNamelc)) {
            parents.add(file);
          }
        });
      }
    });
    imports.forEach((i) {
      String imp = i.toString();
      bool required = false;
      for (int i = 0; i < parents.length; ++i) {
        if (imp.contains(parents[i])) {
          required = true;
          _buffer.write('${imp.replaceAll(new RegExp(".dart'"), ".e.dart'")}\n');
          parents.removeAt(i);
          i--;
        }
      }
      if (!required) {
        required = false;
        _buffer.write('$imp\n');
      }
    });
    parents.forEach((p) 
        => _buffer.write("import '${p.replaceAll(new RegExp(".dart"), ".e.dart")}';\n"));
    return _buffer.toString();
  }
  
  Iterable<EnhancerEntity> _ic;
    
  Iterable<EnhancerEntity> _inheritanceChain () {
    if (null == _ic) {
      EnhancerEntity e = this;
      List<EnhancerEntity> es = <EnhancerEntity>[this];
      while (e.hasParent) {
        e = e.superclass;
        es.add(e);
      }
      _ic = es.reversed;
    }
    return _ic;
  }
  
  String _insert () {
    _buffer
        ..clear()
        ..write('String insert ($entityName $entityNamelc, {bool ignore: false}) {');
    members.forEach((member) => _buffer.write('''
    
    var ${member.vdname} = $entityNamelc.${member.vdname};
    if (${member.vdname} is Entity) {
      ${member.vdname} = ${member.vdname}.entityMetadata.get(${member.vdname}, ${member.vdname}.entityMetadata.idName);
    }'''));
    _buffer.write("\n    return \"INSERT\${ignore ? \'ignore \' : \' \'}INTO $entityName (");
    members.forEach((member) => _buffer.write('${member.vdname}, '));
    String tmp = '${_buffer.toString().substring(0, _buffer.length - 2)}) VALUES (';
    _buffer
        ..clear()
        ..write(tmp);
    members.forEach((member) {
      _buffer.write("\${${member.vdname} is num ? '\${${member.vdname}}' : \"'\${${member.vdname}}'\"}, ");
    });
    return "${_buffer.toString().substring(0, _buffer.length - 2)});\";\n  }";
  }
  
  String _persistables () {
    _buffer
        ..clear()
        ..write('static const Persistable ');
    members.forEach((member) {
      Annotation annotation = member.annotation;
      String annPrefix;
      switch (member.typeName) {
        case 'bool':
          annPrefix = 'Bool';
          break;
        case 'int':
          annPrefix = 'Int';
          break;
        case 'num':
          annPrefix = 'Num';
          break;
        case 'String':
          annPrefix = 'String';
          break;
        default:
          annPrefix = '';
          break;
      }
      _buffer.write('PERSISTABLE_${member.vdnameuc} = const ${annPrefix}Persistable ${annotation.arguments.toString()},\n    ');
    });
    return '${_buffer.toString().substring(0, _buffer.length - 6)};';
  }
  
  String _select () => '''String select ($entityName $entityNamelc, [List<String> fields]) {
    if (null == fields) {
      return 'SELECT * FROM $entityName WHERE $entityName.${identifier.vdname} = \${$entityNamelc.${identifier.vdname}} LIMIT 1';
    } else if (fields.isEmpty) {
      throw new ArgumentError('fields cannot be empty');
    }
    StringBuffer query = new StringBuffer('SELECT ');
    fields.forEach((field) => query.write('\$field, '));
    return "\${query.toString().substring(0, query.length - 2)} FROM $entityName WHERE $entityName.${identifier.vdname} = ${_requiresQuotes(identifier.typeName) ? "'\${$entityNamelc.${identifier.vdname}}'" : '\${$entityNamelc.${identifier.vdname}}'} LIMIT 1;";
  }''';
  
  String _selectAll() => '''String selectAll (List<$entityName> ${entityNamelc}s, [List<String> fields]) {
    if (null == fields) {
      StringBuffer query = new StringBuffer('SELECT * FROM $entityName WHERE $entityName.${identifier.vdname} IN (');
      ${entityNamelc}s.forEach(($entityNamelc) => query.write("'\${$entityNamelc.${identifier.vdname}}', "));
      return '\${query.toString().substring(0, query.length - 2)}) LIMIT \${${entityNamelc}s.length}';
    } else if (fields.isEmpty) {
      throw new ArgumentError('fields cannot be empty');
    }
    StringBuffer query = new StringBuffer('SELECT ');
    fields.forEach((field) => query.write('\$field, '));
    query = new StringBuffer('\${query.toString().substring(0, query.length - 2)} FROM $entityName WHERE $entityName.${identifier.vdname} IN (');
    ${entityNamelc}s.forEach(($entityNamelc) => query.write("${_requiresQuotes(identifier.typeName) ? "'\${$entityNamelc.${identifier.vdname}}'" : '\${$entityNamelc.${identifier.vdname} is num ? $entityNamelc.${identifier.vdname} : "\'\${$entityNamelc.${identifier.vdname}}\'"}'}, "));
    return '\${query.toString().substring(0, query.length - 2)}) LIMIT \${${entityNamelc}s.length};';
  }''';
  
  String _set () {
      _buffer
          ..clear()
          ..write('void set ($entityName $entityNamelc, String field, value) {\n    switch (field) {\n');
      members.forEach((member) => _buffer.write("      case '${member.vdname}':\n        $entityNamelc.${member.vdname} = value;\n        break;\n"));
      return '''$_buffer      default:
        ${hasParent ? 'super.set($entityNamelc, field, value);\n        break;' 
            : "throw new ArgumentError('Invalid field \$field');"}
    }
  }''';
    }
  
  String _setters () {
    _buffer.clear();
    members.forEach((member) => _buffer.write('${member.asSetter()}\n  '));
    return '${_buffer.toString().substring(0, _buffer.length - 3)}'.replaceAll('{{EntityMetaName}}', entityMetaName);
  }
  
  String _symbols() {
    _buffer
        ..clear()
        ..write('static const Symbol ');
    members.forEach((member) => _buffer.write("SYMBOL_${member.vdnameuc} = const Symbol('${member.vdname}'),\n    "));
    return '${_buffer.toString().substring(0, _buffer.length - 6)};';
  }
  
  String _properties () {
    _buffer.clear();
    members.forEach((member) => _buffer.write('${member.asPrivate()}\n  '));
    return '${_buffer.toString().substring(0, _buffer.length - 3)}';
  }
  
  bool _requiresQuotes(String type) {
    switch (type) {
      case 'double':
      case 'float':
      case 'int':
      case 'num':
        return false;
      default:
        return true;
    }
  }
  
  String _sql () {
    _buffer
        ..clear()
        ..write("static const String SQL_CREATE = 'CREATE TABLE $entityName (");
    _inheritanceChain().forEach((entity) {
      entity.members.forEach((member) {
        Map<String, String> args = _annotationArguments(member.annotation);
        String sqlType = _sqlTypeForMember(member);
        _buffer.write('${member.vdname} $sqlType ${args.containsKey('nullable') 
          && 'true' == args['nullable'] ? '': 'NOT'} NULL, ');
      });
    });
    return "${_buffer.toString().substring(0, _buffer.length - 2)}, PRIMARY KEY(${identifier.vdname}));';";
  }
  
  String _sqlTypeForMember (Member member) {
    Map<String, String> args = _annotationArguments(member.annotation);
    switch (member.typeName) {
      case 'float':
        return 'FLOAT';
      case 'int':
        return 'INT';
      case 'double':
      case 'num':
        return 'DOUBLE';
      case 'String':
        if (args.containsKey('max')) {
          return 'VARCHAR(${args['max']})';
        }
        if (args.containsKey('length')) {
          return 'VARCHAR(${args['length']})';
        }
        return 'VARCHAR(256)';
      default:
        EnhancerEntity e = entities.firstWhere((test) =>
            test.entityName == member.typeName, orElse: () => null);
        if (null != e) {
          return _sqlTypeForMember(e.id);
        }
        break;
    }
    return null;
  }
  
  String _toString () {
   _buffer..clear()..write('String toString () => \'\'\'{\n');
   _inheritanceChain().forEach((entity) {
    entity.members.forEach((member) {
      _buffer.write('    ${member.vdname}: \$${member.vdname},\n');
    });
   });
   String str = _buffer.toString();
   return '${str.toString().substring(0, str.length - 2)}\n  }\'\'\';';
  }
  
  String _update () => '''String update ($entityName $entityNamelc, List values, [List<String> fields]) {
    if (null == fields) {
      fields = ${entityName}Meta.FIELDS;
    }
    if (fields.isEmpty) {
      throw new ArgumentError('fields cannot be empty');
    }
    StringBuffer query = new StringBuffer('UPDATE $entityName SET ');
    fields.forEach((f) {
      var value = get($entityNamelc, f);
      if (value is Entity) {
        value = value.entityMetadata.get(value, value.entityMetadata.idName);
      }
      query.write('\$f = \${value is num ? value : "'\$value'"}, ');
    });
    var id = get($entityNamelc, idName);
    return "\${query.toString().substring(0, query.length - 2)} WHERE $entityName.\$idName = \${id is num ? id : "\'\$id\'"};";
  }''';
      
  String toString () => '''${_imports()}
${isAbstract ? 'abstract ' : ''}class $entityName extends ${hasParent ? extendsClause.superclass : 'Entity'} {
  ${_properties()}
  
  ${_constructors()}
  
  ${_getters()}
  $entityMetaName get entityMetadata => _meta;

  ${_hashCode()}
  
  ${_equals()}
  
  ${_setters()}
  
  ${_toString()}
  
  static final $entityMetaName _meta = new $entityMetaName();
}

class $entityMetaName ${hasParent ? 'extends ${extendsClause.superclass}Meta implements' : 'extends'} EntityMeta<$entityName> {

  ${hasParent ? '' : 'String get idName => \'${identifier.vdname}\';\n\n  Symbol get idNameSym => SYMBOL_${identifier.vdnameuc};\n'}
  String get entityName => ENTITY_NAME;

  Symbol get entityNameSym => ENTITY_NAME_SYM;

  List<String> get fields => FIELDS;

  List<Symbol> get fieldsSym => FIELDS_SYM;

  ${_asArray()}

  ${_asMap()}
  
  ${_asMapSym()}
  
  ${_delete()}
  
  ${_get()}
  
  ${_insert()}
  
  ${_select()}
  
  ${_selectAll()}
  
  ${_set()}
  
  ${_update()}
  
  static const String ENTITY_NAME = '$entityName';
  static const Symbol ENTITY_NAME_SYM = const Symbol ('$entityName');
  ${_fields()}
  ${_fieldsList()}
  ${_fieldsListSym()}
  ${_sql()}
  ${_persistables()}
  ${_symbols()}
}
''';
}

class EntityEnhancer extends GeneralizingAstVisitor {
  Annotation _annotation;
  EnhancerEntity _current;
  String _currentFileName;
  Map<String, EnhancerEntity> _entities = <String, EnhancerEntity>{};
  Map<String, List<EnhancerEntity>> _groups = <String, List<EnhancerEntity>>{};
  List<ImportDirective> _imports = <ImportDirective>[];
  TypeName _type;
  int _typeCounter = 0;
  
  /**
   * Exepects a [Map]<[String], [String]> keyed by file path of the source 
   * to parse.
   */
  Map<String, List<String>> enhance (Map<String, String> contents, {bool suppressErrors: false}) {
    contents.forEach((name, source) {
      _currentFileName = name;
      parseCompilationUnit(source, name: name, suppressErrors: suppressErrors)
        .accept(this);
    });
    _entities.values.forEach((entity) {
      if (entity.hasParent) {
        ExtendsClause clause = entity.extendsClause;
        String superclass = clause.superclass.name.name;
        if (_entities.containsKey(superclass)) {
          entity.superclass = _entities[superclass];
        }
      }
      entity.entities = _entities.values;
      entity.files = contents.keys.map((f) => p.basename(f));
    });
    Map<String, List<String>> es = <String, List<String>>{};
    _groups.forEach((file, entities) {
      List<String> enhanced = <String>[];
      entities.forEach((entity) => enhanced.add(entity.toString()));
      es[file] = enhanced;
    });
    return es;
  }
  
  visitAnnotation(Annotation node) {
    _annotation = node;
    super.visitAnnotation(node);
  }
  
  visitClassDeclaration(ClassDeclaration node) {
    _current = new EnhancerEntity(node);
    _current.imports.addAll(_imports);
    super.visitClassDeclaration(node);
    _entities[_current.entityName] = _current;
    List<EnhancerEntity> es;
    if (_groups.containsKey(_currentFileName)) {
      es = _groups[_currentFileName];
    } else {
      _groups[_currentFileName] = es = <EnhancerEntity>[];
    }
    es.add(_current);
    _current = null;
    _imports.clear();
  }
  
  visitMethodDeclaration(MethodDeclaration node) {
    _current.methods.add(node);
    super.visitMethodDeclaration(node);
  }
  
  visitImportDirective(ImportDirective node) {
    super.visitImportDirective(node);
    _imports.add(node);
  }
  
  visitExtendsClause(ExtendsClause node) {
    super.visitExtendsClause(node);
    _type = null;//Necessary or first property will have this type
  }
  
  visitTypeName(TypeName node) {
    if (0 == _typeCounter) {
      _type = node;
    } else {
      --_typeCounter;
    }
    if (null != node.typeArguments) {
      _typeCounter += node.typeArguments.arguments.length;
    }
    super.visitTypeName(node);
  }
  
  visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    if (null != _annotation && _annotation.toString().contains('Id')) {
      _current.id = new Member(_annotation, _type, node);
    }
    _current.members.add(new Member(_annotation, _type, node));
    
    _annotation = null;
    _type = null;
  }
}

class Member {
  final Annotation annotation;
  final String typeName;
  final String vdname, vdnameuc;
  
  Member (Annotation this.annotation, TypeName tn, VariableDeclaration vd) 
  : typeName = null == tn ? tn : tn.toString(),
    vdname = vd.name.toString(),
    vdnameuc = vd.name.toString().toUpperCase();
  
  String get _type => '${typeName == null ? '' : '$typeName'}';
  
  String asGetter () => '$_type get $vdname => _$vdname;';  
  
  String asSetter () => '''set $vdname ($_type $vdname) {
    if ({{EntityMetaName}}.PERSISTABLE_$vdnameuc.validate($vdname)) {
      _$vdname = $vdname;
      if (entityMetadata.syncEnabled(this)) {
        _meta.onChange(this, {{EntityMetaName}}.FIELD_$vdnameuc);
      }
    } else {
      throw new ArgumentError ('$vdname is not valid');
    }
  }''';
  
  String asParameter () => '$_type $vdname';
  
  String asPrivate () => '$_type _$vdname;';
  
  String toString () => '$annotation $_type $vdname;';
}