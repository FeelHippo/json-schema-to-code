import 'dart:io';

import 'package:json_schema_to_code/src/builders/builder_typescript.dart';
import 'package:json_schema_to_code/src/schema_store.dart';

class GeneratorTypescript {
  GeneratorTypescript({
    required this.schemaFile,
    required this.schemaStore,
  });

  final File schemaFile;
  final SchemaStore schemaStore;

  void build() {
    final uri = Uri.file(schemaFile.path);
    final builder = BuilderTypescript(schemaFile, schemaStore, uri);
    final fileName = getFileName();
    final outputFile = File(fileName);
    builder.write(outputFile);
  }

  String getFileName() {
    return '${schemaFile.uri.pathSegments.last.replaceAll(
      '-',
      '_',
    ).replaceAll(
      '.json',
      '',
    )}.ts';
  }
}
