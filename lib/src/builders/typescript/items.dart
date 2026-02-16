part of '../builder_typescript.dart';

mixin Items {
  void writePrefixItems({
    required Schema schema,
    required SchemaStore schemaStore,
    required File outputFile,
    required List<String> Function(Schema schema) readTypeList,
    required String Function(List<String>, Schema schema) typeListToString,
  }) {
    String? propertyType;
    final List<Uri> prefixItemsUris = schema.prefixItems;
    List<String> prefixItemsTypes = <String>[];
    for (final Uri prefixItemsUri in prefixItemsUris) {
      final Schema prefixItemSchema =
          schemaStore.storedBuiltSchemas[prefixItemsUri]!;
      prefixItemsTypes = <String>[
        ...prefixItemsTypes,
        ...readTypeList(prefixItemSchema),
        if (prefixItemSchema.hasEnum)
          '${StringUtils.enumName(prefixItemSchema.schemaName)}Enum',
      ];
    }
    propertyType = typeListToString(prefixItemsTypes, schema);
    OutputUtils.writeLine(
      outputFile,
      'export type ${schema.fullClassName()} = $propertyType;\n',
    );
  }

  void writeEnum({
    required Schema schema,
    required SchemaStore schemaStore,
    required File outputFile,
  }) {
    final List<dynamic>? enumList = schema.enumValue;
    if (enumList == null) return;

    // open -- declare enum name
    OutputUtils.writeLine(
      outputFile,
      'export enum ${StringUtils.enumName(schema.schemaName)}Enum {',
    );

    for (final dynamic enumItem in enumList) {
      OutputUtils.writeLine(
        outputFile,
        '$enumItem,',
        indentation: 2,
      );
    }

    // close enum
    OutputUtils.writeLine(
      outputFile,
      '}\n',
    );
  }
}
