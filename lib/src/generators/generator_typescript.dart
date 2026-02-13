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
    final Uri uri = Uri.file(schemaFile.path);
    final BuilderTypescript builder = BuilderTypescript(
      schemaFile,
      schemaStore,
      uri,
    );
    final String fileName = getFileName();
    final File outputFile = File(fileName);
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
