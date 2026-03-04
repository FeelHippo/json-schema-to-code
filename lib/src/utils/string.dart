import 'package:dart_casing/dart_casing.dart';

class StringUtils {
  static String className(String fullClassName) {
    // only allow alphanumeric class names
    final RegExp alphanumeric = RegExp(r'^[^a-zA-Z0-9_:]+$');
    final String withoutExtension = fullClassName
        .replaceAll('.json', '')
        .replaceAll(alphanumeric, '');
    return Casing.pascalCase(withoutExtension);
  }

  static String enumName(String enumName) {
    return Casing.pascalCase(enumName);
  }

  static String normalizeLine(String line) {
    return line
        .replaceAll(
          '-',
          '_',
        )
        .replaceAll(
          '.json',
          '',
        );
  }
}
