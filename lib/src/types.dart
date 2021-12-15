import 'dart:async';
import 'dart:io';

enum GobiResult { close, next }

typedef GobiMiddleware = FutureOr<GobiResult> Function(GobiRequest request);

abstract class GobiHandler {
  FutureOr<GobiResult> call(GobiRequest request);
}

class GobiComponentContainer {
  late final Map<Type, Object> _components;

  GobiComponentContainer() {
    _components = {};
  }

  GobiComponentContainer.from(GobiComponentContainer other) {
    _components = other._components;
  }

  Object? operator [](Type T) => _components[T];

  T? add<T>(T Function() ifAbsent, [T Function(T value)? update]) {
    if (_components.containsKey(T)) {
      if (update == null) return null;

      _components[T] = update(_components[T] as T) as Object;
    } else {
      _components[T] = ifAbsent() as Object;
    }

    return _components[T] as T;
  }

  T? get<T>() => _components[T] as T?;

  T? remove<T>() => _components.remove(T) as T?;
}

class GobiRequest extends GobiComponentContainer {
  late final HttpRequest httpRequest;

  late String _path;
  late Map<String, String> params;

  GobiRequest(this.httpRequest) {
    path = httpRequest.uri.normalizePath().path;
    params = {};
  }

  GobiRequest.from(GobiRequest other) : super.from(other) {
    httpRequest = other.httpRequest;

    _path = other._path;
    params = Map.of(other.params);
  }

  String get path => _path;
  set path(String value) => _path = value.startsWith("/") ? value : "/" + value;

  GobiRequest clone() => GobiRequest.from(this);
}

class GobiServer {
  late final HttpServer httpServer;
  late final GobiMiddleware handler;

  GobiServer(this.handler, ServerSocket serverSocket) {
    httpServer = HttpServer.listenOn(serverSocket);

    _handleRequests();
  }

  void _handle(HttpRequest httpRequest) async {
    final request = GobiRequest(httpRequest)
      ..add(() => this)
      ..add(() => httpServer)
      ..add(() => httpRequest)
      ..add(() => httpRequest.response);

    await handler(request);
  }

  void _handleRequests() async {
    await for (final httpRequest in httpServer) {
      _handle(httpRequest);
    }
  }
}
