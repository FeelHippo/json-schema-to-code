import 'dart:io';

import 'package:json_schema_to_code/src/utils/string.dart';

class OutputUtils {
  static void writeLine(File outputFile, String line, {int indentation = 0}) {
    outputFile.writeAsStringSync(
      '${' ' * indentation}${StringUtils.normalizeLine(line)}\n',
      mode: FileMode.append,
    );
  }
}
