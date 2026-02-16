part of '../builder_typescript.dart';

mixin Items {
  void writeItem({
    required Schema schema,
    required SchemaStore schemaStore,
    required File outputFile,
    required List<String> Function(Schema schema) readTypeList,
    required String Function(List<String>, Schema schema) typeListToString,
  }) {
    Schema? defSchema;
    String? propertyType;

    defSchema = schemaStore.storedBuiltSchemas[schema.item!];

    if (defSchema == null) {
      return;
    }

    // search for schema if == $dynamicRef | $id | $ref | $schema
    final Map<String, Uri?> uriProperties = defSchema.readTypeURIProperties();
    for (final Uri? uriProperty in uriProperties.values) {
      if (uriProperty != null) {
        defSchema = schemaStore.storedBuiltSchemas[uriProperty];
        if (defSchema != null) {
          final List<String> typeList = readTypeList(defSchema);
          propertyType = typeListToString(typeList, defSchema);
        }
      }
    }

    // $anchor, $comment, $dynamicAnchor, title, description
    // e.g.
    // $anchor : String
    // "$defs": {
    //     "nonEmptyString": {
    //       "$anchor": "internal-string",
    //       "type": "string",
    //       "minLength": 1
    //     }
    //   }
    // TODO(Filippo): this needs review to make sure all cases are covered
    Map<String, String?> propertiesOfTypeString = schema
        .readTypeStringProperties();
    for (final String? propertyOfTypeString in propertiesOfTypeString.values) {
      if (propertyOfTypeString != null) {
        OutputUtils.writeLine(
          outputFile,
          '// $propertyOfTypeString',
        );
      }
    }

    // open type for main schema
    OutputUtils.writeLine(
      outputFile,
      'export type ${schema.fullClassName()} = ${schema.inferType()};\n',
    );

    if (defSchema == null || defSchema.hasBeenWritten) return;
    // $anchor, $comment, $dynamicAnchor, title, description
    propertiesOfTypeString = defSchema.readTypeStringProperties();
    for (final String? propertyOfTypeString in propertiesOfTypeString.values) {
      if (propertyOfTypeString != null) {
        OutputUtils.writeLine(
          outputFile,
          '// $propertyOfTypeString',
        );
      }
    }
    // open type for definition schema
    OutputUtils.writeLine(
      outputFile,
      'export type ${defSchema.fullClassName()} = $propertyType;\n',
    );
  }

  void writeItems({
    required Schema schema,
    required File outputFile,
    required List<String> Function(Schema schema) readTypeList,
    required String Function(List<String>, Schema schema) typeListToString,
  }) {
    String? propertyType;
    final List<String> typeList = readTypeList(schema);
    propertyType = typeListToString(typeList, schema);
    OutputUtils.writeLine(
      outputFile,
      'export type ${schema.fullClassName()} = $propertyType;\n',
    );
  }
}
