import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:json_schema_to_code/src/schema.dart';

class SchemaStore {
  SchemaStore()
    : _rootParsedObject = SplayTreeMap<String, dynamic>(),
      _builtSchemas = SplayTreeMap<Uri, Schema>(),
      _parsedObjects = SplayTreeMap();

  Map<String, dynamic> _rootParsedObject;
  final Map<Uri, Schema> _builtSchemas;
  final Map<Uri, Map?> _parsedObjects;

  void store(String content) =>
      _rootParsedObject = jsonDecode(content) as Map<String, dynamic>;

  Map<Uri, Schema> get storedBuiltSchemas => _builtSchemas;

  Map<Uri, Map<dynamic, dynamic>?> get storedParsedObjects => _parsedObjects;

  Uri? documentUri;

  void registerDocumentUri(String pathToSchema) {
    documentUri = Uri.file(pathToSchema);
  }

  Schema? schemaByUri(Uri uri) {
    if (!_builtSchemas.containsKey(uri)) {
      return _builtSchemas[uri];
    }
    return null;
  }

  void loadSchema(
    Uri uri,
    Schema schema,
    Map<dynamic, dynamic>? object,
  ) {
    // return if this schema has already been processed and stored
    if (_builtSchemas.containsKey(uri)) return;

    // this is the case when we process the root of the json schema file
    if (object == null) {
      final String content = File(uri.toFilePath()).readAsStringSync();
      store(content);
    }

    // nested properties will have an object, but root will not
    _parsedObjects[uri] = object ?? _rootParsedObject;

    // store this branch
    if (!_builtSchemas.containsKey(uri)) {
      _builtSchemas[uri] = schema;
    }
  }
}
