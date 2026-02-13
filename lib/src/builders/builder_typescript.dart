import 'dart:io';

import 'package:json_schema_to_code/src/generators/generator_typescript.dart';
import 'package:json_schema_to_code/src/schema.dart';
import 'package:json_schema_to_code/src/schema_store.dart';
import 'package:json_schema_to_code/src/utils/path.dart';
import 'package:json_schema_to_code/src/utils/string.dart';

class BuilderTypescript extends GeneratorTypescript {
  BuilderTypescript(File schemaFile, SchemaStore schemaStore, this.uri)
    : assert(
        schemaStore.storedParsedObjects[uri] != null,
        'ERROR: schema object not found',
      ),
      super(schemaFile: schemaFile, schemaStore: schemaStore) {
    _schema = Schema(
      uri: uri,
      schemaStore: schemaStore,
      typeInferrer: getInferredTypes,
    );
  }

  final Uri uri;
  late Schema _schema;

  void writeLine(File outputFile, String line, {int indentation = 0}) {
    outputFile.writeAsStringSync(
      '${' ' * indentation}${StringUtils.normalizeLine(line)}\n',
      mode: FileMode.append,
    );
  }

  List<String> readTypeList(Schema defSchema) {
    final List<String> someOfAndPrefixItems =
        <Uri>[...defSchema.someOfUris, ...defSchema.prefixItems].map((
          Uri someOfUri,
        ) {
          final Schema someOfUrisSchema = findSchemaByUri(someOfUri)!;
          for (final Uri? uriProperties
              in someOfUrisSchema.readTypeURIProperties().values) {
            if (uriProperties != null) {
              final Schema someOfUrisSchema = findSchemaByUri(uriProperties)!;
              return someOfUrisSchema.fullClassName();
            }
          }
          final String inferredType = getInferredTypes(someOfUrisSchema);
          return inferredType;
        }).toList();
    if (someOfAndPrefixItems.isNotEmpty) return someOfAndPrefixItems;
    return defSchema.types;
  }

  void writeObject(File outputFile, Schema schema) {
    // interfaces
    if (schema.isClass) {
      if (schema.hasBeenWritten) return;
      Schema? defSchema;
      // open
      writeLine(
        outputFile,
        'export interface ${schema.fullClassName()} {',
      );

      // content
      for (final Uri propertyUri in schema.propertiesUris) {
        final Schema propertySchema = schemaStore.storedBuiltSchemas.entries
            .firstWhere(
              (MapEntry<Uri, Schema> uriToSchema) =>
                  uriToSchema.key == propertyUri,
            )
            .value;

        // $defs: $dynamicRef, $id, $ref, $schema
        final Map<String, Uri?> propertiesOfTypeUri = propertySchema
            .readTypeURIProperties();
        for (final Uri? propertyOfTypeUri in propertiesOfTypeUri.values) {
          if (propertyOfTypeUri != null) {
            defSchema = findSchemaByUri(propertyOfTypeUri);
          }
        }

        // $anchor, $comment, $dynamicAnchor, title, description
        final Map<String, String?> propertiesOfTypeString = propertySchema
            .readTypeStringProperties();
        for (final String? propertyOfTypeString
            in propertiesOfTypeString.values) {
          if (propertyOfTypeString != null) {
            writeLine(
              outputFile,
              '// $propertyOfTypeString',
              indentation: 2,
            );
          }
        }

        final String propertyName = propertySchema.uri.pathSegments.last;
        final String propertyValue =
            defSchema?.fullClassName() ?? propertySchema.inferType();
        final bool isRequired = schema.requiredProperties.contains(
          propertyName,
        );
        writeLine(
          outputFile,
          '$propertyName${isRequired ? '' : '?'}: $propertyValue;',
          indentation: 2,
        );
      }

      // close
      writeLine(
        outputFile,
        '}\n',
      );
      schema.markAsWritten();
      // items property (object schema)
    } else if (schema.hasItem && schema.item != null) {
      Schema? defSchema;
      String? propertyType;
      defSchema = findSchemaByUri(schema.item!);
      if (defSchema != null) {
        final Map<String, Uri?> uriProperties = defSchema
            .readTypeURIProperties();
        // schema is $dynamicRef | $id | $ref | $schema
        for (final Uri? uriProperty in uriProperties.values) {
          if (uriProperty != null) {
            defSchema = findSchemaByUri(uriProperty);
            if (defSchema != null) {
              final List<String> typeList = readTypeList(defSchema);
              propertyType = typeListToString(typeList, defSchema);
            }
          }
        }
      }

      if (!schema.hasBeenWritten) {
        // $anchor, $comment, $dynamicAnchor, title, description
        final Map<String, String?> propertiesOfTypeString = schema
            .readTypeStringProperties();
        for (final String? propertyOfTypeString
            in propertiesOfTypeString.values) {
          if (propertyOfTypeString != null) {
            writeLine(
              outputFile,
              '// $propertyOfTypeString',
            );
          }
        }
        writeLine(
          outputFile,
          'export type ${schema.fullClassName()} = ${schema.inferType()};\n',
        );
        schema.markAsWritten();
      }

      if (defSchema != null) {
        if (defSchema.hasBeenWritten) return;
        // $anchor, $comment, $dynamicAnchor, title, description
        final Map<String, String?> propertiesOfTypeString = defSchema
            .readTypeStringProperties();
        for (final String? propertyOfTypeString
            in propertiesOfTypeString.values) {
          if (propertyOfTypeString != null) {
            writeLine(
              outputFile,
              '// $propertyOfTypeString',
            );
          }
        }
        writeLine(
          outputFile,
          'export type ${defSchema.fullClassName()} = $propertyType;\n',
        );
        defSchema.markAsWritten();
      }
      // items properties (list schema)
    } else if (schema.hasItems) {
      String? propertyType;
      final List<String> typeList = readTypeList(schema);
      propertyType = typeListToString(typeList, schema);
      writeLine(
        outputFile,
        'export type ${schema.fullClassName()} = $propertyType;\n',
      );
    } else if (schema.hasPatternProperties) {
      print(schema.schemaName);
      // open
      writeLine(
        outputFile,
        'export interface RegexMatched${schema.schemaName} {',
      );
      print('~~~ ${schema.uri}');
      for (final MapEntry<String, String> entry
          in schema.patternPropertiesRegexMatcher.entries) {
        final Schema? patternProperties = findSchemaByUri(
          PathUtils.append(schema.uri, entry.key),
        );
        print(
          '~~~ ${patternProperties}',
        );
        // TODO(Filippo): take it from here.
        // entry.key == '0'.
        // entry.value == regex expression.
        // patternProperties == // { '.../fileFormats/0': { "type": "integer" }, '.../fileFormats/1': { "type": "string" } }
        // each line should be [key: RegexMatched${schema.schemaName}<entry.value>]: regex_here (patternProperties[entry.key])
      }
      // close
      writeLine(
        outputFile,
        '}\n',
      );
      schema.markAsWritten();
      for (final MapEntry<String, String> regexMatcher
          in schema.patternPropertiesRegexMatcher.entries) {
        writeLine(
          outputFile,
          'type ${regexMatcher.key}RegexMatched<Pattern extends string> = `\${string & {__brand: Pattern}}`;',
        );
      }
    }
    schema.markAsWritten();
  }

  void write(File outputFile) {
    writeLine(
      outputFile,
      '// this file was autogenerated, please do not modify',
    );
    for (final MapEntry<Uri, Schema> schema
        in schemaStore.storedBuiltSchemas.entries) {
      writeObject(outputFile, schema.value);
    }
  }

  String typeListToString(
    List<String> types,
    Schema schema,
  ) {
    final bool isClassSchema = schema.isClass;
    final String fullClassName = schema.fullClassName();
    final bool hasItems = schema.hasItems || schema.hasItem;
    // https://github.com/jimblackler/jsonschematypes/blob/6054b6283f38b84a8642b6176369ba7526862132/codegen/src/main/java/net/jimblackler/jsonschematypes/codegen/TypeScriptBuilder.java#L56
    String typeOutput = '';
    for (final String type in types) {
      if (isClassSchema) {
        if (typeOutput.isNotEmpty) {
          typeOutput += ' | ';
        }
        typeOutput += fullClassName;
      } else if (type == 'array') {
        if (typeOutput.isNotEmpty) {
          typeOutput += ' | ';
        }
        if (!hasItems) {
          typeOutput += 'Object';
        } else {
          Schema? defSchema;
          final Schema itemsSchema = schema.getChildByUri();
          final Map<String, Uri?> uriProperties = itemsSchema
              .readTypeURIProperties();
          for (final Uri? uriProperty in uriProperties.values) {
            if (uriProperty != null) {
              defSchema = findSchemaByUri(uriProperty);
            }
          }
          final String itemsSchemaFullClassname = itemsSchema.fullClassName();
          typeOutput += defSchema?.fullClassName() ?? itemsSchemaFullClassname;
        }
        typeOutput += '[]';
      } else {
        if (typeOutput.isNotEmpty) {
          typeOutput += ' | ';
        }
        typeOutput += type;
      }
    }
    return typeOutput;
  }

  String getInferredTypes(Schema schema) {
    if (schema.types.isNotEmpty) {
      return typeListToString(
        schema.types,
        schema,
      );
    }
    final List<String> inferredTypes = <String>[];
    if (schema.enumValue != null &&
        schema.enumValue!.every((dynamic value) => value is String)) {
      (schema.enumValue! as List<String>).forEach(inferredTypes.add);
    }
    if (schema.readStringProperties().values.any(
      (String? property) => property != null,
    )) {
      inferredTypes.add('string');
    }
    if (schema.readNumericProperties().values.any(
      (num? property) => property != null,
    )) {
      inferredTypes.add('number');
    }
    if (schema.readListProperties().values.any(
          (num? property) => property != null,
        ) ||
        schema.uniqueItems ||
        schema.hasItems) {
      inferredTypes.add('array');
    }
    if (schema.readObjectProperties().values.any(
          (num? property) => property != null,
        ) ||
        schema.required ||
        schema.requiredProperties.isNotEmpty ||
        schema.dependentRequired.isNotEmpty ||
        schema.isClass ||
        schema.hasPropertyNames) {
      inferredTypes.add('object');
    }
    if (schema.defaultValue != null) {
      final Type dartType = schema.defaultValue.runtimeType;
      if (dartType == String) {
        inferredTypes.add('string');
      } else if (dartType == int || dartType == double) {
        inferredTypes.add('number');
      } else if (dartType == List) {
        inferredTypes.add('array');
      } else if (dartType == Object) {
        inferredTypes.add('object');
      }
    }
    return typeListToString(
      inferredTypes,
      schema,
    );
  }

  Schema? findSchemaByUri(Uri uri) {
    return schemaStore.storedBuiltSchemas[uri];
  }
}
