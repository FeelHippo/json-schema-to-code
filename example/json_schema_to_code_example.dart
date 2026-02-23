import 'package:json_schema_to_code/json_schema_to_code.dart';

void main() {
  SchemaToCode(pathToSchema: 'apple-app-site-association.json');
  SchemaToCode(pathToSchema: 'lego.json');
  SchemaToCode(pathToSchema: 'prefix-items.json');
}
