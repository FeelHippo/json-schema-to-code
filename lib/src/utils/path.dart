class PathUtils {
  static const String ESCAPED_EMPTY = '~2';

  // https://github.com/jimblackler/jsonschemafriend/blob/e66880bae0d86664afb65d0b953872b3e021d48b/library/src/main/java/net/jimblackler/jsonschemafriend/PathUtils.java#L200
  static Uri normalize(Uri uri) {
    final stringified = uri.toFilePath();
    final length = stringified.length;
    if (stringified.endsWith('#')) {
      return Uri.file(stringified.substring(0, length - 1));
    }
    if (stringified.endsWith('#/')) {
      return Uri.file(stringified.substring(0, length - 2));
    }
    return uri;
  }

  static String normalizeReference(String reference) {
    if (reference.startsWith('#/')) {
      return reference.substring(2, reference.length);
    }
    return reference;
  }

  // https://github.com/jimblackler/jsonschemafriend/blob/e66880bae0d86664afb65d0b953872b3e021d48b/library/src/main/java/net/jimblackler/jsonschemafriend/PathUtils.java#L118
  static Uri resolve(Uri base, Uri child) {
    if (child.hasScheme) return child;

    final stringifiedBase = base.toFilePath();
    final stringifiedChild = child.toFilePath();

    final i = stringifiedBase.indexOf('#');
    final baseWithoutFragment = i == -1
        ? stringifiedBase
        : stringifiedBase.substring(0, i);

    if (stringifiedChild[0] == '#') {
      return Uri.file(baseWithoutFragment + stringifiedChild);
    }

    var lastSlashIndex = baseWithoutFragment.lastIndexOf('/');
    if (lastSlashIndex == -1) {
      lastSlashIndex = baseWithoutFragment.lastIndexOf(':');
      if (lastSlashIndex == -1) {
        return child;
      }
    }
    return Uri.file(
      baseWithoutFragment.substring(0, lastSlashIndex + 1) +
          (stringifiedChild[0] == '/'
              ? stringifiedChild.substring(1)
              : stringifiedChild),
    );
  }

  // https://github.com/jimblackler/jsonschemafriend/blob/e66880bae0d86664afb65d0b953872b3e021d48b/library/src/main/java/net/jimblackler/jsonschemafriend/PathUtils.java#L18C10-L35C4
  static Uri append(Uri uri, String value) {
    var uriString = uri.toFilePath();
    if (!uriString.contains('#')) {
      uriString += '#';
    }

    if (uriString[uriString.length - 1] != '/') {
      uriString += '/';
    }

    return Uri.file(uriString + value);
  }
}
