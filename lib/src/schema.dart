// https://github.com/jimblackler/jsonschemafriend/blob/master/library/src/main/java/net/jimblackler/jsonschemafriend/Schema.java
import 'dart:collection';

import 'package:json_schema_to_code/src/schema_store.dart';
import 'package:json_schema_to_code/src/utils/keywords.dart';
import 'package:json_schema_to_code/src/utils/path.dart';
import 'package:json_schema_to_code/src/utils/string.dart';

class Schema {
  Schema({
    required this.uri,
    required this.schemaStore,
    required this.typeInferrer,
    this.object,
  }) : _schemaName = uri.pathSegments.last {
    schemaStore.loadSchema(uri, this, object);
    for (final validator in [
      booleanChecks,
      numericChecks,
      stringChecks,
      arrayChecks,
      objectChecks,
      recursiveParsing,
    ]) {
      validator();
    }
  }

  final Uri uri;

  final SchemaStore schemaStore;

  final String Function(Schema) typeInferrer;

  Map<dynamic, dynamic>? object;

  Schema? _parent;

  String _schemaName;

  bool get hasParent => _parent != null;

  String get schemaName => _schemaName;

  Schema? get parent => _parent;

  String? get parentName => _parent?.schemaName;

  void parentSchema(Schema parentSchema) {
    _parent = parentSchema;
  }

  Schema getChildByUri() {
    final child = schemaStore.builtSchemas.entries
        .where((entry) {
          if (entry.value.parent != null) {
            return entry.value.parent!.uri == uri;
          }
          return false;
        })
        .toList()
        .first
        .value;
    return child;
  }

  String fullClassName() {
    if (!hasParent) {
      return StringUtils.className(_schemaName);
    }
    return StringUtils.className(parent!.schemaName) +
        StringUtils.className(_schemaName);
  }

  String inferType() {
    return typeInferrer(this);
  }

  bool _hasBeenWritten = false;

  bool get hasBeenWritten => _hasBeenWritten;

  void markAsWritten() {
    _hasBeenWritten = true;
  }

  // numeric properties
  num? _multipleOf;
  num? _maximum;
  num? _exclusiveMaximum;
  num? _minimum;
  num? _exclusiveMinimum;
  num? _divisibleBy;

  Map<String, num?> readNumericProperties() {
    final Map<String, num?> properties = HashMap();
    properties['multipleOf'] = _multipleOf;
    properties['maximum'] = _maximum;
    properties['exclusiveMaximum'] = _exclusiveMaximum;
    properties['minimum'] = _minimum;
    properties['exclusiveMinimum'] = _exclusiveMinimum;
    properties['divisibleBy'] = _divisibleBy;
    return properties;
  }

  // string properties
  String? _maxLength;
  String? _minLength;
  String? _pattern;
  String? _format;
  String? _contentEncoding;
  String? _contentMediaType;

  Map<String, String?> readStringProperties() {
    final Map<String, String?> properties = HashMap();
    properties['maxLength'] = _maxLength;
    properties['minLength'] = _minLength;
    properties['pattern'] = _pattern;
    properties['format'] = _format;
    properties['contentEncoding'] = _contentEncoding;
    properties['contentMediaType'] = _contentMediaType;
    return properties;
  }

  // list properties
  num? _maxItems;
  num? _minItems;
  bool _uniqueItems = false;
  bool _hasItems = false;
  bool _hasItem = false;
  bool _hasPrefixItems = false;
  num? _maxContains;
  num? _minContains;

  Map<String, num?> readListProperties() {
    final Map<String, num?> properties = HashMap();
    properties['maxItems'] = _maxItems;
    properties['minItems'] = _minItems;
    properties['maxContains'] = _maxContains;
    properties['minContains'] = _minContains;
    return properties;
  }

  bool get uniqueItems => _uniqueItems;

  bool get hasItems => _hasItems || _hasPrefixItems;

  bool get hasItem => _hasItem;

  // object properties
  num? _maxProperties;
  num? _minProperties;
  bool _required = false;
  bool _hasProperties = false;
  bool _hasPatternProperties = false;
  bool _hasPropertyNames = false;
  final List<String> _requiredProperties = [];
  final List<Uri> _propertiesUris = [];
  final List<Uri> _defsUris = [];
  final Map<String, List<String>> _dependentRequired = HashMap();

  Map<String, num?> readObjectProperties() {
    final Map<String, num?> properties = HashMap();
    properties['maxProperties'] = _maxProperties;
    properties['minProperties'] = _minProperties;
    return properties;
  }

  bool get required => _required;

  bool get hasProperties => _hasProperties;

  bool get isClass => hasProperties;

  bool get hasPatternProperties => _hasPatternProperties;

  bool get hasPropertyNames => _hasPropertyNames;

  List<String> get requiredProperties => _requiredProperties;

  List<Uri> get propertiesUris => _propertiesUris;

  List<Uri> get defsUris => _defsUris;

  Map<String, List<String>> get dependentRequired => _dependentRequired;

  // type properties
  String? _anchor;
  String? _comment;
  String? _dynamicAnchor;
  Uri? _dynamicRef;
  Uri? _id;
  Uri? _ref;
  Uri? _schema;
  String? _title;
  String? _description;
  bool _hasConst = false;
  dynamic _const;
  List<dynamic>? _enum;
  List<String> _types = [];
  dynamic _default;
  final List<dynamic> _examples = [];

  Map<String, String?> readTypeStringProperties() {
    final Map<String, String?> properties = HashMap();
    properties['anchor'] = _anchor;
    properties['comment'] = _comment;
    properties['dynamicAnchor'] = _dynamicAnchor;
    properties['title'] = _title;
    properties['description'] = _description;
    properties['pattern'] = _pattern;
    return properties;
  }

  Map<String, Uri?> readTypeURIProperties() {
    final Map<String, Uri?> properties = HashMap();
    properties['dynamicRef'] = _dynamicRef;
    properties['id'] = _id;
    properties['ref'] = _ref;
    properties['schema'] = _schema;
    return properties;
  }

  bool get hasConst => _hasConst;

  dynamic get constValue => _const;

  List<dynamic>? get enumValue => _enum;

  List<String> get types => _types;

  dynamic get defaultValue => _default;

  List<dynamic> get examples => _examples;

  void validateRecursively<T>(Map<dynamic, dynamic> parsedObject, String key) {
    for (final property in parsedObject.entries) {
      if (property.key == key) {
        assert(
          property.value is T,
          'ERROR: invalid type ${property.key}: ${property.value}',
        );
      }
      if (property.value is Map) {
        validateRecursively<T>(property.value as Map<dynamic, dynamic>, key);
      }
    }
  }

  final List<Uri> _someOfUris = [];

  List<Uri> get someOfUris => _someOfUris;

  bool _hasSomeOf = false;

  bool get hasSomeOf => _hasSomeOf;

  final List<Uri> _items = [];

  List<Uri> get items => [..._items, ..._prefixItems];

  Uri? _item;

  Uri? get item => _item;

  final List<Uri> _prefixItems = [];

  List<Uri> get prefixItems => _prefixItems;

  // [bool, Type.BOOLEAN],
  // [num, Type.NUMBER],
  // [String, Type.STRING],
  // [List, Type.ARRAY],
  // [Map, Type.OBJECT]

  void booleanChecks() {
    final parsedObject = schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.BOOLEAN).forEach((key) {
      validateRecursively<bool>(parsedObject!, key);
    });
  }

  void numericChecks() {
    final parsedObject = schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.NUMBER).forEach((key) {
      validateRecursively<num>(parsedObject!, key);
    });
  }

  void stringChecks() {
    final parsedObject = schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.STRING).forEach((key) {
      validateRecursively<String>(parsedObject!, key);
    });
  }

  void arrayChecks() {
    final parsedObject = schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.ARRAY).forEach((key) {
      validateRecursively<List<dynamic>>(parsedObject!, key);
    });
  }

  Schema newSchema({
    required Uri uri,
    required SchemaStore schemaStore,
    required Map object,
  }) {
    return Schema(
      uri: uri,
      schemaStore: schemaStore,
      object: object,
      typeInferrer: typeInferrer,
    );
  }

  void objectChecks() {
    final parsedObject = schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.OBJECT).forEach((key) {
      validateRecursively<Object>(parsedObject!, key);
    });
  }

  void recursiveParsing() {
    final parsedObject = schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    if (parsedObject!.containsKey('multipleOf')) {
      _multipleOf = parsedObject['multipleOf'] as num?;
    }
    if (parsedObject.containsKey('maximum')) {
      _maximum = parsedObject['maximum'] as num?;
    }
    if (parsedObject.containsKey('exclusiveMaximum')) {
      _exclusiveMaximum = parsedObject['exclusiveMaximum'] as num?;
    }
    if (parsedObject.containsKey('minimum')) {
      _minimum = parsedObject['minimum'] as num?;
    }
    if (parsedObject.containsKey('exclusiveMinimum')) {
      _exclusiveMinimum = parsedObject['exclusiveMinimum'] as num?;
    }
    if (parsedObject.containsKey('divisibleBy')) {
      _divisibleBy = parsedObject['divisibleBy'] as num?;
    }
    if (parsedObject.containsKey('maxLength')) {
      _maxLength = parsedObject['maxLength'] as String?;
    }
    if (parsedObject.containsKey('minLength')) {
      _minLength = parsedObject['minLength'] as String?;
    }
    if (parsedObject.containsKey('pattern')) {
      _pattern = parsedObject['pattern'] as String?;
    }
    if (parsedObject.containsKey('format')) {
      final dynamic format = parsedObject['format'];
      _format = format is String ? format : null;
    }
    if (parsedObject.containsKey('contentEncoding')) {
      final dynamic contentEncoding = parsedObject['contentEncoding'];
      _contentEncoding = contentEncoding is String ? contentEncoding : null;
    }
    if (parsedObject.containsKey('contentMediaType')) {
      final dynamic contentMediaType = parsedObject['contentMediaType'];
      _contentMediaType = contentMediaType is String ? contentMediaType : null;
    }
    if (parsedObject.containsKey('prefixItems')) {
      final dynamic prefixItems = parsedObject['prefixItems'];
      if (prefixItems is List) {
        for (var i = 0; i < prefixItems.length; i++) {
          if (prefixItems[i] is Map) {
            final schemaUri = PathUtils.append(uri, 'prefixItems$i');
            newSchema(
              uri: schemaUri,
              schemaStore: schemaStore,
              object: prefixItems[i] as Map<dynamic, dynamic>,
            ).parentSchema(this);
            _prefixItems.add(schemaUri);
            _hasPrefixItems = true;
          }
        }
      }
    }
    if (parsedObject.containsKey('unevaluatedItems')) {
      final unevaluatedItems = parsedObject['unevaluatedItems'];
      if (unevaluatedItems is Map) {
        newSchema(
          uri: PathUtils.append(uri, 'unevaluatedItems'),
          schemaStore: schemaStore,
          object: unevaluatedItems,
        );
      }
    }
    if (parsedObject.containsKey('items')) {
      final dynamic items = parsedObject['items'];
      if (items is List) {
        for (var i = 0; i < items.length; i++) {
          if (items[i] is Map) {
            final schemaUri = PathUtils.append(uri, 'items$i');
            newSchema(
              uri: schemaUri,
              schemaStore: schemaStore,
              object: items[i] as Map<dynamic, dynamic>,
            ).parentSchema(this);
            _items.add(schemaUri);
          }
        }
        _hasItems = true;
      } else if (items is Map) {
        final schemaUri = PathUtils.append(uri, 'items');
        newSchema(
          uri: schemaUri,
          schemaStore: schemaStore,
          object: items,
        ).parentSchema(this);
        _item = schemaUri;
        _hasItem = true;
      }
    }
    if (parsedObject.containsKey('maxItems')) {
      _maxItems = parsedObject['maxItems'] as num?;
    }
    if (parsedObject.containsKey('minItems')) {
      _minItems = parsedObject['minItems'] as num?;
    }
    if (parsedObject.containsKey('minContains')) {
      _minContains = parsedObject['minContains'] as num?;
    }
    if (parsedObject.containsKey('maxContains')) {
      _maxContains = parsedObject['maxContains'] as num?;
    }
    if (parsedObject.containsKey('uniqueItems')) {
      _uniqueItems = parsedObject['uniqueItems'] as bool;
    }
    if (parsedObject.containsKey('contains')) {
      final contains = parsedObject['contains'];
      if (contains is Map) {
        newSchema(
          uri: PathUtils.append(uri, 'contains'),
          schemaStore: schemaStore,
          object: contains,
        );
      }
    }
    if (parsedObject.containsKey('maxProperties')) {
      _maxProperties = parsedObject['maxProperties'] as num?;
    }
    if (parsedObject.containsKey('minProperties')) {
      _minProperties = parsedObject['minProperties'] as num?;
    }
    if (parsedObject.containsKey('required')) {
      final required = parsedObject['required'];
      if (required is List) {
        for (var i = 0; i < required.length; i++) {
          if (required[i] is String) {
            _requiredProperties.add(required[i] as String);
          }
        }
      } else if (required is bool) {
        _required = required;
      }
    }
    if (parsedObject.containsKey('additionalProperties')) {
      final additionalProperties = parsedObject['additionalProperties'];
      if (additionalProperties is Map) {
        newSchema(
          uri: PathUtils.append(uri, 'contains'),
          schemaStore: schemaStore,
          object: additionalProperties,
        );
      }
    }
    if (parsedObject.containsKey('unevaluatedProperties')) {
      final unevaluatedProperties = parsedObject['unevaluatedProperties'];
      if (unevaluatedProperties is Map) {
        newSchema(
          uri: PathUtils.append(uri, 'contains'),
          schemaStore: schemaStore,
          object: unevaluatedProperties,
        );
      }
    }
    if (parsedObject.containsKey(r'$defs')) {
      final defs = parsedObject[r'$defs'];
      if (defs is Map) {
        final refPointer = PathUtils.append(uri, r'$defs');
        for (final entry in defs.entries) {
          if (entry.key is String && entry.value is Map) {
            final schemaUri = PathUtils.append(refPointer, entry.key as String);
            newSchema(
              uri: schemaUri,
              schemaStore: schemaStore,
              object: entry.value as Map,
            ).parentSchema(this);
            _defsUris.add(schemaUri);
          }
        }
      }
    }
    if (parsedObject.containsKey('properties')) {
      final properties = parsedObject['properties'];
      if (properties is Map) {
        final propertiesPointer = PathUtils.append(uri, 'properties');
        for (final entry in properties.entries) {
          if (entry.key is String && entry.value is Map) {
            final propertyUri = PathUtils.append(
              propertiesPointer,
              entry.key as String,
            );
            newSchema(
              uri: propertyUri,
              schemaStore: schemaStore,
              object: entry.value as Map,
            ).parentSchema(this);
            _hasProperties = true;
            _propertiesUris.add(propertyUri);
          }
        }
      }
    }
    if (parsedObject.containsKey('patternProperties')) {
      final patternProperties = parsedObject['patternProperties'];
      if (patternProperties is Map) {
        final patternPropertiesPointer = PathUtils.append(
          uri,
          'patternProperties',
        );
        for (final entry in patternProperties.entries) {
          if (entry.key is String && entry.value is Map) {
            newSchema(
              uri: PathUtils.append(
                patternPropertiesPointer,
                entry.key as String,
              ),
              schemaStore: schemaStore,
              object: entry.value as Map,
            ).parentSchema(this);
          }
        }
        _hasPatternProperties = true;
      }
    }
    if (parsedObject.containsKey('dependentRequired')) {
      final dependentRequired = parsedObject['dependentRequired'];
      if (dependentRequired is Map) {
        for (final entry in dependentRequired.entries) {
          final values = <String>[];
          for (final dependentRequiredValue in entry.value as List<dynamic>) {
            if (dependentRequiredValue is String) {
              values.add(dependentRequiredValue);
            }
          }
          if (entry.key is String) {
            _dependentRequired[entry.key as String] = values;
          }
        }
      }
    }
    if (parsedObject.containsKey('dependentSchemas')) {
      final dependentSchemas = parsedObject['dependentSchemas'];
      if (dependentSchemas is Map) {
        final dependentSchemasPointer = PathUtils.append(
          uri,
          'dependentSchemas',
        );
        for (final entry in dependentSchemas.entries) {
          if (entry.key is String && entry.value is Map) {
            newSchema(
              uri: PathUtils.append(
                dependentSchemasPointer,
                entry.key as String,
              ),
              schemaStore: schemaStore,
              object: entry.value as Map,
            ).parentSchema(this);
          }
        }
      }
    }
    if (parsedObject.containsKey('propertyNames')) {
      final propertyNames = parsedObject['propertyNames'];
      if (propertyNames is Map) {
        newSchema(
          uri: PathUtils.append(uri, 'propertyNames'),
          schemaStore: schemaStore,
          object: propertyNames,
        );
        _hasPropertyNames = true;
      }
    }
    if (parsedObject.containsKey('const')) {
      final constValue = parsedObject['const'];
      _hasConst = true;
      _const = constValue;
    }
    if (parsedObject.containsKey('enum')) {
      final enumValue = parsedObject['enum'];
      if (enumValue is List) {
        _enum = enumValue;
      }
    }
    if (parsedObject.containsKey('type')) {
      final typeValue = parsedObject['type'];
      if (typeValue is String) {
        _types = [typeValue];
      }
      if (typeValue is List<String>) {
        _types = typeValue;
      }
    }
    for (final key in ['if', 'then', 'else']) {
      if (parsedObject.containsKey(key)) {
        final jsonSchema = parsedObject[key];
        if (jsonSchema is Map) {
          newSchema(
            uri: PathUtils.append(uri, key),
            schemaStore: schemaStore,
            object: jsonSchema,
          );
        }
      }
    }
    for (final key in ['allOf', 'anyOf', 'oneOf']) {
      if (parsedObject.containsKey(key)) {
        final jsonSchema = parsedObject[key];
        if (jsonSchema is List) {
          final keyUri = PathUtils.append(
            uri,
            key,
          );
          for (var i = 0; i < jsonSchema.length; i++) {
            if (jsonSchema[i] is Map) {
              final propertyUri = PathUtils.append(keyUri, '$i');
              newSchema(
                uri: propertyUri,
                schemaStore: schemaStore,
                object: jsonSchema[i] as Map,
              ).parentSchema(this);
              _someOfUris.add(propertyUri);
            }
          }
          _hasSomeOf = true;
        }
      }
    }
    // String
    for (final pair in [
      [r'$anchor', (String value) => _anchor = value],
      [r'$comment', (String value) => _comment = value],
      [r'$dynamicAnchor', (String value) => _dynamicAnchor = value],
    ]) {
      final key = pair[0];
      final capsule = pair[1] as void Function(String);
      if (parsedObject.containsKey(key)) {
        final jsonSchema = parsedObject[key];
        if (jsonSchema is String) {
          capsule(jsonSchema);
        }
      }
    }
    // URI
    for (final pair in [
      [
        r'$dynamicRef',
        (String value) => _dynamicRef = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
      [
        r'$id',
        (String value) => _id = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
      [
        r'$ref',
        (String value) => _ref = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
      [
        r'$schema',
        (String value) => _schema = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
    ]) {
      final key = pair[0];
      final capsule = pair[1] as void Function(String);
      if (parsedObject.containsKey(key)) {
        final jsonSchema = parsedObject[key];
        if (jsonSchema is String) {
          capsule(jsonSchema);
        }
      }
    }
    if (parsedObject.containsKey('not')) {
      final not = parsedObject['not'];
      if (not is Map) {
        newSchema(
          uri: PathUtils.append(uri, 'not'),
          schemaStore: schemaStore,
          object: not,
        );
      }
    }
    if (parsedObject.containsKey('default')) {
      final defaultValue = parsedObject['default'];
      _default = defaultValue;
    }
    if (parsedObject.containsKey('title')) {
      final title = parsedObject['title'];
      if (title is String) {
        _title = title;
      }
    }
    if (parsedObject.containsKey('description')) {
      final description = parsedObject['description'];
      if (description is String) {
        _description = description;
      }
    }
    if (parsedObject.containsKey('examples')) {
      final examples = parsedObject['examples'];
      if (examples is List) {
        examples.forEach(_examples.add);
      }
    }
  }
}
