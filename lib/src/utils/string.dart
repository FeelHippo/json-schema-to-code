import 'package:dart_casing/dart_casing.dart';

class StringUtils {
  static String className(String fullClassName) {
    final withoutExtension = fullClassName.replaceAll('.json', '');
    return Casing.pascalCase(withoutExtension);
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
