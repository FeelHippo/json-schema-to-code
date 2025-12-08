import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:json_schema_to_code/src/schema.dart';

class SchemaStore {
  SchemaStore()
    : documentUriParsedObject = HashMap(),
      builtSchemas = HashMap(),
      parsedObjects = HashMap();

  Map<dynamic, dynamic> documentUriParsedObject;

  final Map<Uri, Schema> builtSchemas;
  final Map<Uri, Map?> parsedObjects;

  Uri? documentUri;

  void registerDocumentUri(String pathToSchema) {
    documentUri = Uri.file(pathToSchema);
  }

  Schema? schemaByUri(Uri uri) {
    if (!builtSchemas.containsKey(uri)) {
      return builtSchemas[uri];
    }
    return null;
  }

  Map<Uri, Map<dynamic, dynamic>?> get storedParsedObjects => parsedObjects;

  Map<Uri, Schema> get storedBuiltSchemas => builtSchemas;

  void loadSchema(
    Uri uri,
    Schema schema,
    Map<dynamic, dynamic>? object,
  ) {
    if (builtSchemas.containsKey(uri)) return;

    if (object == null) {
      final content = File(uri.toFilePath()).readAsStringSync();
      store(content);
    }

    parsedObjects[uri] = object ?? getObject();

    if (!builtSchemas.containsKey(uri)) {
      builtSchemas[uri] = schema;
    }
  }

  void store(String content) =>
      documentUriParsedObject = jsonDecode(content) as Map<String, dynamic>;

  Map<dynamic, dynamic>? getObject() {
    return documentUriParsedObject;
  }
}
