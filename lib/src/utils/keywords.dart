import 'dart:collection';

enum Type {
  // Properties
  SCHEMA,
  MAP_OF_SCHEMAS,
  MAP_OF_BOOLEANS,
  MAP_OF_ARRAY,
  LIST_OF_SCHEMAS,
  // Variables
  ANY,
  STRING,
  URI,
  NUMBER,
  OBJECT,
  ARRAY,
  BOOLEAN,
  NULL,
  REGEX,
}

class Keywords {
  static Type get(String key) => getKeyTypes()[key] ?? Type.ANY;

  static List<String> getAllKeysByValue(Type type) => getKeyTypes().entries
      .where((item) => item.value == type)
      .map((item) => item.key)
      .toList();

  static bool isVariable(Type type) => [
    Type.ANY,
    Type.STRING,
    Type.URI,
    Type.NUMBER,
    Type.BOOLEAN,
    Type.OBJECT,
    Type.ARRAY,
    Type.REGEX,
    Type.NULL,
  ].contains(type);

  static bool isSchema(Type type) => [Type.SCHEMA].contains(type);

  static bool isMapOfSchema(Type type) => [Type.MAP_OF_SCHEMAS].contains(type);

  static bool isListOfSchema(Type type) =>
      [Type.LIST_OF_SCHEMAS].contains(type);

  // https://json-schema.org/understanding-json-schema/keywords
  static Map<String, Type> getKeyTypes() {
    // Draft 2020-12
    final Map<String, Type> keyTypes = HashMap();
    // $anchor : String
    // "$defs": {
    //     "nonEmptyString": {
    //       "$anchor": "internal-string",
    //       "type": "string",
    //       "minLength": 1
    //     }
    //   }
    keyTypes[r'$anchor'] = Type.STRING;
    // $comment : String
    // "properties": {
    //     "name": {
    //       "$comment": "TODO: Add `pattern` to better validate names",
    //       "type": "string"
    //     }
    //   }
    keyTypes[r'$comment'] = Type.STRING;
    // $defs : Object<String, Schema>
    // "$defs": {
    //     "nonEmptyString": {
    //       "type": "string",
    //       "minLength": 1
    //     }
    //   }
    keyTypes[r'$defs'] = Type.MAP_OF_SCHEMAS;
    // $dynamicAnchor : String
    // "$defs": {
    //     "default": {
    //       "$comment": "This is a default declaration to satisfy the bookending requirement",
    //       "$dynamicAnchor": "generic-list-item"
    //     }
    //   }
    keyTypes[r'$dynamicAnchor'] = Type.STRING;
    // https://json-schema.org/draft/2020-12/json-schema-core#dynamic-ref
    // $ref : URI Reference
    // "properties": {
    //     "byAbsoluteURI": {
    //       "$dynamicRef": "urn:example:my-other-schema"
    //     }
    //   }
    keyTypes[r'$dynamicRef'] = Type.URI;
    // $id : URI Reference
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "$id": "https://example.com/schemas/even-number.json",
    //   "type": "number",
    //   "multipleOf": 2
    // }
    keyTypes[r'$id'] = Type.URI;
    // $ref : URI Reference
    // "properties": {
    //     "byAbsoluteURI": {
    //       "$ref": "urn:example:my-other-schema"
    //     }
    //   }
    keyTypes[r'$ref'] = Type.URI;
    // $schema : URI
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "type": "string"
    // }
    keyTypes[r'$schema'] = Type.URI;
    // $vocabulary : Object<URI, Boolean>
    // "$vocabulary": {
    //     "https://json-schema.org/draft/2020-12/vocab/core": true,
    //     "https://json-schema.org/draft/2020-12/vocab/applicator": true,
    //     "https://json-schema.org/draft/2020-12/vocab/unevaluated": true,
    //     "https://json-schema.org/draft/2020-12/vocab/validation": true,
    //     "https://json-schema.org/draft/2020-12/vocab/meta-data": true,
    //     "https://json-schema.org/draft/2020-12/vocab/format-annotation": true,
    //     "https://json-schema.org/draft/2020-12/vocab/content": true
    //   },
    keyTypes[r'$vocabulary'] = Type.MAP_OF_BOOLEANS;
    // additionalProperties : Schema
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "additionalProperties": { "type": "integer" }
    // }
    keyTypes['additionalProperties'] = Type.SCHEMA;
    // allOf + anyOf : Array<Schema>
    // "allOf": [
    //     { "$ref": "#/$defs/foo" },
    //     { "$ref": "#/$defs/bar" }
    //   ],
    keyTypes['allOf'] = Type.LIST_OF_SCHEMAS;
    keyTypes['anyOf'] = Type.LIST_OF_SCHEMAS;
    // const : Any
    // "const": 5
    keyTypes['const'] = Type.ANY;
    // contains : Schema
    // "contains": {
    //     "type": "number",
    //     "multipleOf": 2
    //   }
    keyTypes['contains'] = Type.SCHEMA;
    // contentEncoding : String
    // "contentEncoding": "base64"
    keyTypes['contentEncoding'] = Type.STRING;
    // contentMediaType : String
    // "contentMediaType": "text/html"
    keyTypes['contentMediaType'] = Type.STRING;
    // contentSchema : Schema
    // "contentSchema": { "type": "object" }
    keyTypes['contentSchema'] = Type.SCHEMA;
    // default : Any
    // "default": {},
    keyTypes['default'] = Type.ANY;
    // dependentRequired : Object<String, Array<String>>
    // "dependentRequired": {
    //     "foo": [ "bar", "baz" ]
    //   }
    keyTypes['dependentRequired'] = Type.MAP_OF_ARRAY;
    // dependentSchemas : Object<String, Schema>
    // "dependentSchemas": {
    //     "foo": { "maxProperties": 2 },
    //     "bar": { "minProperties": 2 }
    //   }
    keyTypes['dependentSchemas'] = Type.MAP_OF_SCHEMAS;
    // deprecated : Boolean
    // "properties": {
    //     "country": { "type": "string" },
    //     "city": { "type": "string", "deprecated": true }
    //   }
    keyTypes['deprecated'] = Type.BOOLEAN;
    // description : String
    // "description": "This schema describes an even number",
    keyTypes['description'] = Type.STRING;
    // else : Schema
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "if": { "multipleOf": 2 },
    //   "else": { "minimum": 0 }
    // }
    keyTypes['else'] = Type.SCHEMA;
    // enum : Array<Any>
    // "enum": [ "red", "green", "blue" ]
    keyTypes['enum'] = Type.ARRAY;
    // examples : Array<Any>
    // "examples": [
    //     { "name": "John Doe", "age": 23 }
    //   ],
    keyTypes['examples'] = Type.ARRAY;
    // exclusiveMaximum + exclusiveMinimum : Number
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "exclusiveMaximum": 10
    // }
    keyTypes['exclusiveMaximum'] = Type.NUMBER;
    keyTypes['exclusiveMinimum'] = Type.NUMBER;
    // format : String
    // see supported values here
    // https://www.learnjsonschema.com/2020-12/format-annotation/format/
    keyTypes['format'] = Type.STRING;
    // if : Schema
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "if": { "multipleOf": 2 },
    //   "then": { "minimum": 0 },
    //   "else": { "exclusiveMaximum": 0 }
    // }
    keyTypes['if'] = Type.SCHEMA;
    // items : Schema
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "items": { "type": "number" }
    // }
    // OR
    // "items": { "$ref": "#/some/uri" }
    // hence, this should be ANY, and Schema will take care to create a dedicated object
    keyTypes['items'] = Type.ANY;
    // maxContains : Integer
    // A schema that constrains array instances to contain at most two even numbers:
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "maxContains": 2,
    //   "contains": {
    //     "type": "number",
    //     "multipleOf": 2
    //   }
    // }
    keyTypes['maxContains'] = Type.NUMBER;
    // all below numeric properties : Number
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "maximum": 10
    // }
    keyTypes['maximum'] = Type.NUMBER;
    keyTypes['maxItems'] = Type.NUMBER;
    keyTypes['maxLength'] = Type.NUMBER;
    keyTypes['maxProperties'] = Type.NUMBER;
    keyTypes['minContains'] = Type.NUMBER;
    keyTypes['minimum'] = Type.NUMBER;
    keyTypes['minItems'] = Type.NUMBER;
    keyTypes['minLength'] = Type.NUMBER;
    keyTypes['minProperties'] = Type.NUMBER;
    keyTypes['multipleOf'] = Type.NUMBER;
    // not : Schema
    // "not": {
    //     "title": "I will never be emitted as an annotation",
    //     "const": "Prohibited"
    //   }
    keyTypes['not'] = Type.SCHEMA;
    // oneOf : Array<Schema>
    // "oneOf": [
    //     { "required": [ "foo" ] },
    //     { "required": [ "bar" ] },
    //     { "required": [ "baz" ] }
    //   ]
    keyTypes['oneOf'] = Type.LIST_OF_SCHEMAS;
    // pattern : String
    // "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    keyTypes['pattern'] = Type.REGEX;
    // patternProperties : Object<String, Schema>
    // "patternProperties": {
    //     "^[a-z]+$": { "type": "integer" }
    //   }
    keyTypes['patternProperties'] = Type.MAP_OF_SCHEMAS;
    // prefixItems : Array<Schema>
    // "prefixItems": [ { "type": "boolean" }, { "type": "number" } ]
    keyTypes['prefixItems'] = Type.LIST_OF_SCHEMAS;
    // properties : Object<String, Schema>
    // "properties": {
    //     "name": { "type": "string" },
    //     "age": { "type": "integer" }
    //   }
    keyTypes['properties'] = Type.MAP_OF_SCHEMAS;
    // propertyNames : Schema
    // "propertyNames": { "pattern": "^[a-z]*$" }
    keyTypes['propertyNames'] = Type.SCHEMA;
    // readOnly : Boolean
    // "properties": {
    //     "id": { "type": "integer", "readOnly": true },
    //     "value": { "type": "integer" }
    //   }
    keyTypes['readOnly'] = Type.BOOLEAN;
    // required : Array<String>
    // "required": [ "foo", "bar", "baz" ]
    keyTypes['required'] = Type.ARRAY;
    // then : Schema
    // {
    //   "$schema": "https://json-schema.org/draft/2020-12/schema",
    //   "if": { "multipleOf": 2 },
    //   "then": { "minimum": 0 }
    // }
    keyTypes['then'] = Type.SCHEMA;
    // title : String
    // "title": "Even Number",
    keyTypes['title'] = Type.STRING;
    // type : String | Array<String>
    // "type": "number"
    // OR
    // "type": [ "boolean", "array" ]
    keyTypes['type'] = Type.ANY;
    // unevaluatedItems + unevaluatedProperties : Schema
    // "unevaluatedItems": { "type": "number" }
    keyTypes['unevaluatedItems'] = Type.SCHEMA;
    keyTypes['unevaluatedProperties'] = Type.SCHEMA;
    // uniqueItems + writeOnly : Boolean
    // "uniqueItems": true
    keyTypes['uniqueItems'] = Type.BOOLEAN;
    keyTypes['writeOnly'] = Type.BOOLEAN;
    return keyTypes;
  }
}
