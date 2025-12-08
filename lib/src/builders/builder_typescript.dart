import 'dart:io';

import 'package:json_schema_to_code/src/generators/generator_typescript.dart';
import 'package:json_schema_to_code/src/schema.dart';
import 'package:json_schema_to_code/src/schema_store.dart';
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
    final someOfAndPrefixItems =
        [...defSchema.someOfUris, ...defSchema.prefixItems].map((someOfUri) {
          final someOfUrisSchema = findSchemaByUri(someOfUri)!;
          for (final uriProperties
              in someOfUrisSchema.readTypeURIProperties().values) {
            if (uriProperties != null) {
              final someOfUrisSchema = findSchemaByUri(uriProperties)!;
              return someOfUrisSchema.fullClassName();
            }
          }
          final inferredType = getInferredTypes(someOfUrisSchema);
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
      for (final propertyUri in schema.propertiesUris) {
        final propertySchema = schemaStore.builtSchemas.entries
            .firstWhere(
              (uriToSchema) => uriToSchema.key == propertyUri,
            )
            .value;

        // $defs: $dynamicRef, $id, $ref, $schema
        final propertiesOfTypeUri = propertySchema.readTypeURIProperties();
        for (final propertyOfTypeUri in propertiesOfTypeUri.values) {
          if (propertyOfTypeUri != null) {
            defSchema = findSchemaByUri(propertyOfTypeUri);
          }
        }

        // $anchor, $comment, $dynamicAnchor, title, description
        final propertiesOfTypeString = propertySchema
            .readTypeStringProperties();
        for (final propertyOfTypeString in propertiesOfTypeString.values) {
          if (propertyOfTypeString != null) {
            writeLine(
              outputFile,
              '// $propertyOfTypeString',
              indentation: 2,
            );
          }
        }

        final propertyName = propertySchema.uri.pathSegments.last;
        final propertyValue =
            defSchema?.fullClassName() ?? propertySchema.inferType();
        final isRequired = schema.requiredProperties.contains(propertyName);
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
        final uriProperties = defSchema.readTypeURIProperties();
        // schema is $dynamicRef | $id | $ref | $schema
        for (final uriProperty in uriProperties.values) {
          if (uriProperty != null) {
            defSchema = findSchemaByUri(uriProperty);
            if (defSchema != null) {
              final typeList = readTypeList(defSchema);
              propertyType = typeListToString(typeList, defSchema);
            }
          }
        }
      }

      if (!schema.hasBeenWritten) {
        // $anchor, $comment, $dynamicAnchor, title, description
        final propertiesOfTypeString = schema.readTypeStringProperties();
        for (final propertyOfTypeString in propertiesOfTypeString.values) {
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
        final propertiesOfTypeString = defSchema.readTypeStringProperties();
        for (final propertyOfTypeString in propertiesOfTypeString.values) {
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
      final typeList = readTypeList(schema);
      propertyType = typeListToString(typeList, schema);
      writeLine(
        outputFile,
        'export type ${schema.fullClassName()} = $propertyType;\n',
      );
    }
    schema.markAsWritten();
  }

  void write(File outputFile) {
    writeLine(
      outputFile,
      '// this file was autogenerated, please do not modify',
    );
    for (final schema in schemaStore.builtSchemas.entries) {
      writeObject(outputFile, schema.value);
    }
  }

  String typeListToString(
    List<String> types,
    Schema schema,
  ) {
    final isClassSchema = schema.isClass;
    final fullClassName = schema.fullClassName();
    final hasItems = schema.hasItems || schema.hasItem;
    // https://github.com/jimblackler/jsonschematypes/blob/6054b6283f38b84a8642b6176369ba7526862132/codegen/src/main/java/net/jimblackler/jsonschematypes/codegen/TypeScriptBuilder.java#L56
    var typeOutput = '';
    for (final type in types) {
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
          final itemsSchema = schema.getChildByUri();
          final uriProperties = itemsSchema.readTypeURIProperties();
          for (final uriProperty in uriProperties.values) {
            if (uriProperty != null) {
              defSchema = findSchemaByUri(uriProperty);
            }
          }
          final itemsSchemaFullClassname = itemsSchema.fullClassName();
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
    final inferredTypes = <String>[];
    if (schema.enumValue != null &&
        schema.enumValue!.every((value) => value is String)) {
      schema.enumValue! as List<String>..forEach(inferredTypes.add);
    }
    if (schema.readStringProperties().values.any(
      (property) => property != null,
    )) {
      inferredTypes.add('string');
    }
    if (schema.readNumericProperties().values.any(
      (property) => property != null,
    )) {
      inferredTypes.add('number');
    }
    if (schema.readListProperties().values.any(
          (property) => property != null,
        ) ||
        schema.uniqueItems ||
        schema.hasItems) {
      inferredTypes.add('array');
    }
    if (schema.readObjectProperties().values.any(
          (property) => property != null,
        ) ||
        schema.required ||
        schema.requiredProperties.isNotEmpty ||
        schema.dependentRequired.isNotEmpty ||
        schema.isClass ||
        schema.hasPatternProperties ||
        schema.hasPropertyNames) {
      inferredTypes.add('object');
    }
    if (schema.defaultValue != null) {
      final dartType = schema.defaultValue.runtimeType;
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
    return schemaStore.builtSchemas[uri];
  }
}
