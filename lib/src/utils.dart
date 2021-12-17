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
