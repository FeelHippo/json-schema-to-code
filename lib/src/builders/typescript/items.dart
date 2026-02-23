part of '../builder_typescript.dart';

mixin Items {
  void writeItems({
    required Schema schema,
    required List<Uri> items,
    required SchemaStore schemaStore,
    required File outputFile,
    required List<String> Function(Schema schema) readTypeList,
    required String Function(List<String>, Schema schema) typeListToString,
  }) {
    String? propertyType;
    List<String> someOfTypes = <String>[];
    for (final Uri item in items) {
      Schema? defSchema;
      final Schema itemSchema = schemaStore.storedBuiltSchemas[item]!;

      // $defs: $dynamicRef, $id, $ref, $schema
      final Map<String, Uri?> propertiesUri = itemSchema
          .readTypeURIProperties();
      for (final Uri? propertyUri in propertiesUri.values) {
        if (propertyUri != null) {
          defSchema = schemaStore.storedBuiltSchemas[propertyUri];
        }
      }

      someOfTypes = <String>[
        ...someOfTypes,
        ...readTypeList(itemSchema),
        if (defSchema != null) defSchema.fullClassName(),
        if (itemSchema.hasEnum)
          '${StringUtils.enumName(itemSchema.fullClassName())}Enum',
      ];
    }
    propertyType = typeListToString(someOfTypes, schema);
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
      'export enum ${StringUtils.enumName(schema.fullClassName())}Enum {',
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
