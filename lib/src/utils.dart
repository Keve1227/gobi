String intToString(int number, int zeroPadding) =>
    number.toString().padLeft(zeroPadding, '0');

String lastModifiedFormat(DateTime time) {
  const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  time = time.toUtc();
  return "${weekdays[time.weekday - 1]}, ${time.day} ${months[time.month - 1]} ${time.year} "
      "${intToString(time.hour, 2)}:${intToString(time.minute, 2)}:${intToString(time.second, 2)} "
      "GMT";
}

RegExp pathToRegExp(String path) {
  var pattern = "^";
  RegExpMatch? match;

  while (true) {
    if (match is RegExpMatch) {
      path = path.substring(match.end);
    }

    match = RegExp(r"^/*$").firstMatch(path);
    if (match is RegExpMatch) {
      break;
    }

    match = RegExp(r"^/*\*$").firstMatch(path);
    if (match is RegExpMatch) {
      pattern += r"/?.*$";
      break;
    }

    match = RegExp(r"^/*\*").firstMatch(path);
    if (match is RegExpMatch) {
      pattern += r"/.+?";
      continue;
    }

    match = RegExp(r"^\\(.)").firstMatch(path);
    if (match is RegExpMatch) {
      pattern += match.group(1) ?? "";
      continue;
    }

    match = RegExp(r"^/+:([a-z_][a-z_0-9]*)(?=$|/)").firstMatch(path);
    if (match is RegExpMatch) {
      pattern += "/(?<${match.group(1)}>[^/]+)";
      continue;
    }

    match = RegExp(r"^/+").firstMatch(path);
    if (match is RegExpMatch) {
      pattern += r"/";
      continue;
    }

    match = RegExp(r"^[^/]*").firstMatch(path);
    if (match is RegExpMatch) {
      pattern += RegExp.escape(match.group(0) ?? "");
      continue;
    }
  }

  return RegExp(pattern, caseSensitive: false, unicode: true);
}

String resolvePath(String path, {String? root, bool windows = false}) {
  final pathUri = Uri.file(path, windows: windows);
  var uri = pathUri;

  if (root != null) {
    final rootUri = Uri.directory(root, windows: windows);
    uri = rootUri.resolveUri(pathUri);

    if (!uri.path.startsWith(rootUri.path)) {
      throw ArgumentError.value(
          path, "path", "Path refers outside the root directory");
    }
  } else if (!pathUri.isAbsolute) {
    throw ArgumentError.value(
        path, "path", "Path is relative but no root is specified");
  }

  return uri.toFilePath(windows: windows);
}
