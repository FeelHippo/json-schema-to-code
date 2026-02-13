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
    for (final void Function() validator in <void Function()>[
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

  Map<String, dynamic>? object;

  Schema? _parent;

  final String _schemaName;

  bool get hasParent => _parent != null;

  String get schemaName => _schemaName;

  Schema? get parent => _parent;

  String? get parentName => _parent?.schemaName;

  void parentSchema(Schema parentSchema) {
    _parent = parentSchema;
  }

  Schema getChildByUri() {
    final Schema child = schemaStore.storedBuiltSchemas.entries
        .where((MapEntry<Uri, Schema> entry) {
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
    final Map<String, num?> properties = HashMap<String, num?>();
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
  final List<String> _requiredProperties = <String>[];
  final List<Uri> _propertiesUris = <Uri>[];
  final List<Uri> _defsUris = <Uri>[];
  final Map<String, List<String>> _dependentRequired =
      HashMap<String, List<String>>();
  final HashMap<String, String> _patternPropertiesRegexMatcher =
      HashMap<String, String>(); // <name, pattern>

  Map<String, num?> readObjectProperties() {
    final Map<String, num?> properties = HashMap<String, num?>();
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

  Map<String, String> get patternPropertiesRegexMatcher =>
      _patternPropertiesRegexMatcher;

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
  List<String> _types = <String>[];
  dynamic _default;
  final List<dynamic> _examples = <dynamic>[];

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
    for (final MapEntry<dynamic, dynamic> property in parsedObject.entries) {
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

  final List<Uri> _someOfUris = <Uri>[];

  List<Uri> get someOfUris => _someOfUris;

  bool _hasSomeOf = false;

  bool get hasSomeOf => _hasSomeOf;

  final List<Uri> _items = <Uri>[];

  List<Uri> get items => <Uri>[..._items, ..._prefixItems];

  Uri? _item;

  Uri? get item => _item;

  final List<Uri> _prefixItems = <Uri>[];

  List<Uri> get prefixItems => _prefixItems;

  // [bool, Type.BOOLEAN],
  // [num, Type.NUMBER],
  // [String, Type.STRING],
  // [List, Type.ARRAY],
  // [Map, Type.OBJECT]

  void booleanChecks() {
    final Map<dynamic, dynamic>? parsedObject =
        schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.BOOLEAN).forEach((String key) {
      validateRecursively<bool>(parsedObject!, key);
    });
  }

  void numericChecks() {
    final Map<dynamic, dynamic>? parsedObject =
        schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.NUMBER).forEach((String key) {
      validateRecursively<num>(parsedObject!, key);
    });
  }

  void stringChecks() {
    final Map<dynamic, dynamic>? parsedObject =
        schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.STRING).forEach((String key) {
      validateRecursively<String>(parsedObject!, key);
    });
  }

  void arrayChecks() {
    final Map<dynamic, dynamic>? parsedObject =
        schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.ARRAY).forEach((String key) {
      validateRecursively<List<dynamic>>(parsedObject!, key);
    });
  }

  Schema newSchema({
    required Uri uri,
    required SchemaStore schemaStore,
    required Map<String, dynamic> object,
  }) {
    return Schema(
      uri: uri,
      schemaStore: schemaStore,
      object: object,
      typeInferrer: typeInferrer,
    );
  }

  void objectChecks() {
    final Map<dynamic, dynamic>? parsedObject =
        schemaStore.storedParsedObjects[uri];

    assert(parsedObject != null, 'ERROR: invalid schema object');
    Keywords.getAllKeysByValue(Type.OBJECT).forEach((String key) {
      validateRecursively<Object>(parsedObject!, key);
    });
  }

  void recursiveParsing() {
    final Map<dynamic, dynamic>? parsedObject =
        schemaStore.storedParsedObjects[uri];

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
        for (int i = 0; i < prefixItems.length; i++) {
          if (prefixItems[i] is Map<String, dynamic>) {
            final Uri schemaUri = PathUtils.append(uri, 'prefixItems$i');
            newSchema(
              uri: schemaUri,
              schemaStore: schemaStore,
              object: prefixItems[i] as Map<String, dynamic>,
            ).parentSchema(this);
            _prefixItems.add(schemaUri);
            _hasPrefixItems = true;
          }
        }
      }
    }
    if (parsedObject.containsKey('unevaluatedItems')) {
      final dynamic unevaluatedItems = parsedObject['unevaluatedItems'];
      if (unevaluatedItems is Map<String, dynamic>) {
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
        for (int i = 0; i < items.length; i++) {
          if (items[i] is Map<String, dynamic>) {
            final Uri schemaUri = PathUtils.append(uri, 'items$i');
            newSchema(
              uri: schemaUri,
              schemaStore: schemaStore,
              object: items[i] as Map<String, dynamic>,
            ).parentSchema(this);
            _items.add(schemaUri);
          }
        }
        _hasItems = true;
      } else if (items is Map<String, dynamic>) {
        final Uri schemaUri = PathUtils.append(uri, 'items');
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
      final dynamic contains = parsedObject['contains'];
      if (contains is Map<String, dynamic>) {
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
      final dynamic required = parsedObject['required'];
      if (required is List) {
        for (int i = 0; i < required.length; i++) {
          if (required[i] is String) {
            _requiredProperties.add(required[i] as String);
          }
        }
      } else if (required is bool) {
        _required = required;
      }
    }
    if (parsedObject.containsKey('additionalProperties')) {
      final dynamic additionalProperties = parsedObject['additionalProperties'];
      if (additionalProperties is Map<String, dynamic>) {
        newSchema(
          uri: PathUtils.append(uri, 'contains'),
          schemaStore: schemaStore,
          object: additionalProperties,
        );
      }
    }
    if (parsedObject.containsKey('unevaluatedProperties')) {
      final dynamic unevaluatedProperties =
          parsedObject['unevaluatedProperties'];
      if (unevaluatedProperties is Map<String, dynamic>) {
        newSchema(
          uri: PathUtils.append(uri, 'contains'),
          schemaStore: schemaStore,
          object: unevaluatedProperties,
        );
      }
    }
    if (parsedObject.containsKey(r'$defs')) {
      final dynamic defs = parsedObject[r'$defs'];
      if (defs is Map<String, dynamic>) {
        final Uri refPointer = PathUtils.append(uri, r'$defs');
        for (final MapEntry<String, dynamic> entry in defs.entries) {
          if (entry.value is Map) {
            final Uri schemaUri = PathUtils.append(refPointer, entry.key);
            newSchema(
              uri: schemaUri,
              schemaStore: schemaStore,
              object: entry.value as Map<String, dynamic>,
            ).parentSchema(this);
            _defsUris.add(schemaUri);
          }
        }
      }
    }
    if (parsedObject.containsKey('properties')) {
      final dynamic properties = parsedObject['properties'];
      if (properties is Map<String, dynamic>) {
        final Uri propertiesPointer = PathUtils.append(uri, 'properties');
        for (final MapEntry<String, dynamic> entry in properties.entries) {
          final dynamic value = entry.value;
          if (value is Map<String, dynamic>) {
            final Uri propertyUri = PathUtils.append(
              propertiesPointer,
              entry.key,
            );
            newSchema(
              uri: propertyUri,
              schemaStore: schemaStore,
              object: value,
            ).parentSchema(this);
            _hasProperties = true;
            _propertiesUris.add(propertyUri);
          }
        }
      }
    }
    if (parsedObject.containsKey('patternProperties')) {
      final dynamic patternProperties = parsedObject['patternProperties'];
      if (patternProperties is Map<String, dynamic>) {
        patternProperties.entries.toList().asMap().forEach((
          int index,
          MapEntry<String, dynamic> entry,
        ) {
          final dynamic key = entry.key;
          final dynamic value = entry.value;
          if (key is String) {
            // { 0: '^[a-z]+$', 1: '^[a-z]+$', ... }
            _patternPropertiesRegexMatcher.addAll(<String, String>{
              '$index': key,
            });
          }
          if (value is Map<String, dynamic>) {
            // { '.../fileFormats/0': { "type": "integer" }, '.../fileFormats/1': { "type": "string" } }
            newSchema(
              uri: PathUtils.append(uri, '$index'),
              schemaStore: schemaStore,
              object: value,
            ).parentSchema(this);
          }
        });
        _hasPatternProperties = true;
      }
    }
    if (parsedObject.containsKey('dependentRequired')) {
      final dynamic dependentRequired = parsedObject['dependentRequired'];
      if (dependentRequired is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> entry
            in dependentRequired.entries) {
          final List<String> values = <String>[];
          final dynamic value = entry.value;
          if (value is List) {
            for (final dynamic dependentRequiredValue in value) {
              if (dependentRequiredValue is String) {
                values.add(dependentRequiredValue);
              }
            }
          }
          _dependentRequired[entry.key] = values;
        }
      }
    }
    if (parsedObject.containsKey('dependentSchemas')) {
      final dynamic dependentSchemas = parsedObject['dependentSchemas'];
      if (dependentSchemas is Map<String, dynamic>) {
        final Uri dependentSchemasPointer = PathUtils.append(
          uri,
          'dependentSchemas',
        );
        for (final MapEntry<String, dynamic> entry
            in dependentSchemas.entries) {
          final dynamic value = entry.value;
          if (value is Map<String, dynamic>) {
            newSchema(
              uri: PathUtils.append(
                dependentSchemasPointer,
                entry.key,
              ),
              schemaStore: schemaStore,
              object: value,
            ).parentSchema(this);
          }
        }
      }
    }
    if (parsedObject.containsKey('propertyNames')) {
      final dynamic propertyNames = parsedObject['propertyNames'];
      if (propertyNames is Map<String, dynamic>) {
        newSchema(
          uri: PathUtils.append(uri, 'propertyNames'),
          schemaStore: schemaStore,
          object: propertyNames,
        );
        _hasPropertyNames = true;
      }
    }
    if (parsedObject.containsKey('const')) {
      final dynamic constValue = parsedObject['const'];
      _hasConst = true;
      _const = constValue;
    }
    if (parsedObject.containsKey('enum')) {
      final dynamic enumValue = parsedObject['enum'];
      if (enumValue is List) {
        _enum = enumValue;
      }
    }
    if (parsedObject.containsKey('type')) {
      final dynamic typeValue = parsedObject['type'];
      if (typeValue is String) {
        _types = <String>[typeValue];
      }
      if (typeValue is List<String>) {
        _types = typeValue;
      }
    }
    for (final String key in <String>['if', 'then', 'else']) {
      if (parsedObject.containsKey(key)) {
        final dynamic jsonSchema = parsedObject[key];
        if (jsonSchema is Map<String, dynamic>) {
          newSchema(
            uri: PathUtils.append(uri, key),
            schemaStore: schemaStore,
            object: jsonSchema,
          );
        }
      }
    }
    for (final String key in <String>['allOf', 'anyOf', 'oneOf']) {
      if (parsedObject.containsKey(key)) {
        final dynamic jsonSchema = parsedObject[key];
        if (jsonSchema is List) {
          final Uri keyUri = PathUtils.append(
            uri,
            key,
          );
          for (int i = 0; i < jsonSchema.length; i++) {
            final dynamic value = jsonSchema[i];
            if (value is Map<String, dynamic>) {
              final Uri propertyUri = PathUtils.append(keyUri, '$i');
              newSchema(
                uri: propertyUri,
                schemaStore: schemaStore,
                object: value,
              ).parentSchema(this);
              _someOfUris.add(propertyUri);
            }
          }
          _hasSomeOf = true;
        }
      }
    }
    // String
    for (final List<Object> pair in <List<Object>>[
      <Object>[r'$anchor', (String value) => _anchor = value],
      <Object>[r'$comment', (String value) => _comment = value],
      <Object>[r'$dynamicAnchor', (String value) => _dynamicAnchor = value],
    ]) {
      final Object key = pair[0];
      final void Function(String) capsule = pair[1] as void Function(String);
      if (parsedObject.containsKey(key)) {
        final dynamic jsonSchema = parsedObject[key];
        if (jsonSchema is String) {
          capsule(jsonSchema);
        }
      }
    }
    // URI
    for (final List<Object> pair in <List<Object>>[
      <Object>[
        r'$dynamicRef',
        (String value) => _dynamicRef = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
      <Object>[
        r'$id',
        (String value) => _id = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
      <Object>[
        r'$ref',
        (String value) => _ref = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
      <Object>[
        r'$schema',
        (String value) => _schema = PathUtils.append(
          schemaStore.documentUri!,
          PathUtils.normalizeReference(value),
        ),
      ],
    ]) {
      final Object key = pair[0];
      final void Function(String) capsule = pair[1] as void Function(String);
      if (parsedObject.containsKey(key)) {
        final dynamic jsonSchema = parsedObject[key];
        if (jsonSchema is String) {
          capsule(jsonSchema);
        }
      }
    }
    if (parsedObject.containsKey('not')) {
      final dynamic not = parsedObject['not'];
      if (not is Map<String, dynamic>) {
        newSchema(
          uri: PathUtils.append(uri, 'not'),
          schemaStore: schemaStore,
          object: not,
        );
      }
    }
    if (parsedObject.containsKey('default')) {
      final dynamic defaultValue = parsedObject['default'];
      _default = defaultValue;
    }
    if (parsedObject.containsKey('title')) {
      final dynamic title = parsedObject['title'];
      if (title is String) {
        _title = title;
      }
    }
    if (parsedObject.containsKey('description')) {
      final dynamic description = parsedObject['description'];
      if (description is String) {
        _description = description;
      }
    }
    if (parsedObject.containsKey('examples')) {
      final dynamic examples = parsedObject['examples'];
      if (examples is List) {
        examples.forEach(_examples.add);
      }
    }
  }
}
