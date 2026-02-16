part of '../builder_typescript.dart';

mixin Class {
  void writeClass({
    required Schema schema,
    required SchemaStore schemaStore,
    required File outputFile,
  }) {
    Schema? defSchema;
    // open -- declare interface name
    OutputUtils.writeLine(
      outputFile,
      'export interface ${schema.fullClassName()} {',
    );

    // content of "properties" schema
    // properties : Object<String, Schema>
    // "properties": {
    //     "name": { "type": "string" },
    //     "age": { "type": "integer" }
    //   }
    for (final Uri propertyUri in schema.propertiesUris) {
      final Schema? propertySchema =
          schemaStore.storedBuiltSchemas[propertyUri];

      if (propertySchema == null) {
        return;
      }

      // $defs: $dynamicRef, $id, $ref, $schema
      // e.g.
      // $ref : URI Reference
      // "properties": {
      //     "byAbsoluteURI": {
      //       "$ref": "urn:example:my-other-schema"
      //     }
      //   }
      final Map<String, Uri?> propertiesOfTypeUri = propertySchema
          .readTypeURIProperties();
      for (final Uri? propertyOfTypeUri in propertiesOfTypeUri.values) {
        if (propertyOfTypeUri != null) {
          defSchema = schemaStore.storedBuiltSchemas[propertyOfTypeUri];
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
      final Map<String, String?> propertiesOfTypeString = propertySchema
          .readTypeStringProperties();
      for (final String? propertyOfTypeString
          in propertiesOfTypeString.values) {
        if (propertyOfTypeString != null) {
          OutputUtils.writeLine(
            outputFile,
            '// $propertyOfTypeString',
            indentation: 2,
          );
        }
      }

      // assign name
      final String propertyName = propertySchema.uri.pathSegments.last;

      // assign value -- defSchema has right of way
      final String propertyValue =
          defSchema?.fullClassName() ?? propertySchema.inferType();

      // determine TypeScript requirement
      final bool isRequired = schema.requiredProperties.contains(
        propertyName,
      );

      OutputUtils.writeLine(
        outputFile,
        '$propertyName${isRequired ? '' : '?'}: $propertyValue;',
        indentation: 2,
      );
    }

    // close interface
    OutputUtils.writeLine(
      outputFile,
      '}\n',
    );
  }

  void writePatternProperties({
    required Schema schema,
    required SchemaStore schemaStore,
    required File outputFile,
  }) {
    // open
    OutputUtils.writeLine(
      outputFile,
      'export interface ${schema.schemaName}RegexMatched {',
    );
    for (final MapEntry<String, String> entry
        in schema.patternPropertiesRegexMatcher.entries) {
      Schema? defSchema;
      final Schema? patternPropertiesSchema = schemaStore
          .storedBuiltSchemas[PathUtils.append(schema.uri, entry.key)];
      if (patternPropertiesSchema == null) {
        return;
      }

      // $defs: $dynamicRef, $id, $ref, $schema
      final Map<String, Uri?> propertiesOfTypeUri = patternPropertiesSchema
          .readTypeURIProperties();
      for (final Uri? propertyOfTypeUri in propertiesOfTypeUri.values) {
        if (propertyOfTypeUri != null) {
          defSchema = schemaStore.storedBuiltSchemas[propertyOfTypeUri];
        }
      }

      // $anchor, $comment, $dynamicAnchor, title, description
      final Map<String, String?> propertiesOfTypeString =
          patternPropertiesSchema.readTypeStringProperties();
      for (final String? propertyOfTypeString
          in propertiesOfTypeString.values) {
        if (propertyOfTypeString != null) {
          OutputUtils.writeLine(
            outputFile,
            '// $propertyOfTypeString',
            indentation: 2,
          );
        }
      }
      final String propertyValue =
          defSchema?.fullClassName() ?? patternPropertiesSchema.inferType();

      OutputUtils.writeLine(
        outputFile,
        '[key: RegexMatched${entry.key}<"${entry.value}">]: $propertyValue;',
        indentation: 2,
      );
    }
    // close
    OutputUtils.writeLine(
      outputFile,
      '}\n',
    );
    // https://www.geeksforgeeks.org/typescript/how-to-define-a-regex-matched-string-type-in-typescript/
    for (final MapEntry<String, String> regexMatcher
        in schema.patternPropertiesRegexMatcher.entries) {
      OutputUtils.writeLine(
        outputFile,
        'type RegexMatched${regexMatcher.key}<Pattern extends string> = `\${string & {__brand: Pattern}}`;',
      );
    }
  }
}
