import 'dart:async';

import 'package:gobi/src/types.dart';

class GobiStatic extends GobiHandler {
  final String root;
  final String? index;
  final int maxAge;
  final bool lastModified, cacheControl, immutable, dotfiles, windows;

  GobiStatic(
    this.root, {
    this.index = "index.html",
    this.maxAge = 0,
    this.lastModified = true,
    this.cacheControl = true,
    this.immutable = false,
    this.dotfiles = false,
    this.windows = false,
  });

  @override
  FutureOr<void> call(GobiRequest request) async {
    if (request.method != "GET") return;
    final path = "." + (request.path == "/" ? "" : request.path);

    try {
      await request.sendFile(
        path,
        root: root,
        maxAge: maxAge,
        lastModified: lastModified,
        cacheControl: cacheControl,
        immutable: immutable,
        dotfiles: dotfiles,
        windows: windows,
      );

      return;
    } catch (_) {
      if (index == null) {
        return;
      }
    }

    try {
      await request.sendFile(
        "$path/$index",
        root: root,
        maxAge: maxAge,
        lastModified: lastModified,
        cacheControl: cacheControl,
        immutable: immutable,
        dotfiles: dotfiles,
        windows: windows,
      );

      return;
    } catch (_) {}
  }
}
