import 'dart:io';

import 'package:json_schema_to_code/src/generators/generator_typescript.dart';
import 'package:json_schema_to_code/src/schema_store.dart';

class SchemaToCode {
  SchemaToCode({
    required this.pathToSchema,
  }) : _schemaFile = File(pathToSchema),
       _schemaStore = SchemaStore()..registerDocumentUri(pathToSchema) {
    assert(
      File(_schemaFile.path).existsSync(),
      'Error: ${_schemaFile.path} not found',
    );
    GeneratorTypescript(
      schemaFile: _schemaFile,
      schemaStore: _schemaStore,
    ).build();
    _GeneratorDart(schemaFile: _schemaFile);
  }

  SchemaToCode.typescriptOnly({required this.pathToSchema})
    : _schemaFile = File(pathToSchema),
      _schemaStore = SchemaStore() {
    assert(
      File(_schemaFile.path).existsSync(),
      'Error: ${_schemaFile.path} not found',
    );
    GeneratorTypescript(
      schemaFile: _schemaFile,
      schemaStore: _schemaStore,
    ).build();
  }

  SchemaToCode.dartOnly({required this.pathToSchema})
    : _schemaFile = File(pathToSchema),
      _schemaStore = SchemaStore() {
    assert(
      File(_schemaFile.path).existsSync(),
      'Error: ${_schemaFile.path} not found',
    );
    _GeneratorDart(schemaFile: _schemaFile);
  }

  // File system
  final String pathToSchema;
  final File _schemaFile;
  final SchemaStore _schemaStore;
}

class _GeneratorDart {
  const _GeneratorDart({
    required this.schemaFile,
  });

  final File schemaFile;
}
