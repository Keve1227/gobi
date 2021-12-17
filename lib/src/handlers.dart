import 'dart:async';

import 'package:gobi/src/types.dart';

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

class GobiMethodHandler extends GobiHandler {
  late final Pattern method;
  final GobiMiddleware handler;

  GobiMethodHandler(this.method, this.handler);

  @override
  Future<void> call(GobiRequest request) async {
    if (request.path != "/") return;
    if (method.matchAsPrefix(request.method) == null) return;

    await handler(request);
  }
}

class GobiRoute extends GobiHandler {
  final List<GobiMiddleware> _middlewares = [];

  late final Pattern path;

  GobiRoute(Pattern path) {
    if (path is String) {
      this.path = pathToRegExp(path);
      // print((this.path as RegExp).pattern);
    } else {
      this.path = path;
    }
  }

  void all(GobiMiddleware middleware) =>
      _middlewares.add(GobiMethodHandler("", middleware));

  @override
  Future<void> call(GobiRequest request) async {
    final match = path.matchAsPrefix(request.path, 0);
    if (match == null) return;

    request = request.clone();
    request.path = request.path.substring(match.end);

    if (match is RegExpMatch) {
      request.params.addAll({
        for (final name in match.groupNames)
          name: Uri.decodeComponent(match.namedGroup(name) ?? ""),
      });
    }

    for (final handler in _middlewares) {
      await handler(request);

      if (request.done) break;
    }
  }

  void delete(GobiMiddleware middleware) =>
      _middlewares.add(GobiMethodHandler("DELETE", middleware));

  void get(GobiMiddleware middleware) =>
      _middlewares.add(GobiMethodHandler("GET", middleware));

  void options(GobiMiddleware middleware) =>
      _middlewares.add(GobiMethodHandler("OPTIONS", middleware));

  void patch(GobiMiddleware middleware) =>
      _middlewares.add(GobiMethodHandler("PATCH", middleware));

  void post(GobiMiddleware middleware) =>
      _middlewares.add(GobiMethodHandler("POST", middleware));

  void put(GobiMiddleware middleware) =>
      _middlewares.add(GobiMethodHandler("PUT", middleware));

  GobiRoute route(Pattern path) {
    final route = GobiRoute(path);
    _middlewares.add(route);
    return route;
  }

  void use(GobiMiddleware middleware) => _middlewares.add(middleware);
}