import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gobi/src/utils.dart';
import 'package:mime/mime.dart' as mime;

typedef GobiMiddleware = FutureOr<void> Function(GobiRequest request);

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

abstract class GobiHandler {
  FutureOr<void> call(GobiRequest request);
}

class GobiRequest extends GobiComponentContainer {
  late final HttpRequest _request;
  late final GobiRequest _root;

  late String _path;
  late Map<String, String> _params;

  bool _done = false;

  GobiRequest(this._request) {
    _root = this;

    path = _request.uri.normalizePath().path;
    _params = {};

    _request.response.done.whenComplete(() => _done = true);
  }

  GobiRequest.from(GobiRequest other) : super.from(other) {
    _request = other._request;
    _root = other._root;

    _path = other._path;
    _params = Map.of(other._params);
  }

  Future<dynamic> get body async => jsonDecode((await text) ?? "null");

  Future<List<int>> get bytes => request.expand((e) => e).toList();

  String? get charset => contentType?.charset;

  ContentType? get contentType => headers.contentType;

  List<Cookie> get cookies => request.cookies;

  bool get done => _root._done;

  Encoding? get encoding => Encoding.getByName(charset);

  HttpHeaders get headers => request.headers;

  String get host => uri.host;

  int? get localPort => request.connectionInfo?.localPort;

  String get method => request.method;

  String? get mimeType => contentType?.mimeType;

  String get origin => uri.origin;

  String get originalPath => uri.path;

  Map<String, String> get params => _params;

  String get path => _path;

  set path(String value) {
    _path = value.startsWith("/") ? value : "/" + value;
  }

  bool get persistentConnection => request.persistentConnection;

  int get port => uri.port;

  String get protocolVersion => request.protocolVersion;

  Map<String, String> get query => uri.queryParameters;

  InternetAddress? get remoteAddress => request.connectionInfo?.remoteAddress;

  int? get remotePort => request.connectionInfo?.remotePort;

  HttpRequest get request => _request;

  HttpResponse get response => request.response;

  String get scheme => uri.scheme;

  HttpSession get session => request.session;

  Future<String?> get text async => encoding?.decode(await bytes);

  Uri get uri => request.requestedUri;

  GobiRequest append(String name, Object value) {
    response.headers.add(name, value);
    return this;
  }

  GobiRequest attachment([String? filename]) {
    var contentDisposition = "attachment";

    if (filename != null) {
      contentDisposition += "; filename=${Uri.encodeComponent(filename)}";
    }

    return set("content-disposition", contentDisposition);
  }

  GobiRequest clone() => GobiRequest.from(this);

  GobiRequest cookie(
    String name,
    String value, {
    String? domain,
    DateTime? expires,
    bool httpOnly = true,
    int? maxAge,
    String? path,
    bool secure = false,
  }) {
    response.cookies.add(Cookie(name, value)
      ..domain = domain
      ..expires = expires
      ..httpOnly = httpOnly
      ..maxAge = maxAge
      ..path = path
      ..secure = secure);

    return this;
  }

  Future<void> download(
    String path, {
    String? filename,
    String? root,
    int maxAge = 0,
    bool lastModified = true,
    bool cacheControl = true,
    bool immutable = false,
    bool dotfiles = false,
    bool windows = false,
  }) async {
    filename ??= File(path).uri.path.split("/").last;

    await attachment(filename).sendFile(
      path,
      root: root,
      maxAge: maxAge,
      lastModified: lastModified,
      cacheControl: cacheControl,
      immutable: immutable,
      dotfiles: dotfiles,
      windows: windows,
    );
  }

  Future<void> end() async {
    await response.flush();

    if (response.headers.contentType == null &&
        response.headers.contentLength > 0) {
      type("application/octet-stream");
    }

    await response.close();
  }

  GobiRequest expires(DateTime? expires) {
    response.headers.expires = expires;
    return this;
  }

  List<String>? header(String name) {
    return response.headers[name];
  }

  Future<void> json(Object object,
      {Object? Function(Object? nonEncodable)? toEncodable}) async {
    final json = jsonEncode(object, toEncodable: toEncodable);
    await type("json").send(utf8.encode(json));
  }

  GobiRequest reason(String reasonPhrase) {
    response.reasonPhrase = reasonPhrase;
    return this;
  }

  Future<void> redirect(String path,
      [int statusCode = HttpStatus.movedTemporarily]) async {
    await response.flush();
    await response.redirect(Uri.parse(path), status: statusCode);
  }

  Future<void> send(Object object) async {
    response.write(object);
    await end();
  }

  Future<void> sendFile(
    String path, {
    String? root,
    int maxAge = 0,
    bool lastModified = true,
    bool cacheControl = true,
    bool immutable = false,
    bool dotfiles = false,
    bool windows = false,
  }) async {
    if (!dotfiles) {
      final pathSegments = Uri.file(path, windows: windows).pathSegments;
      final hasDotfile =
          pathSegments.indexWhere((segment) => segment.startsWith(".")) > 0;

      if (hasDotfile) {
        throw ArgumentError.value(path, "path",
            "Path may not contain a dotfile unless dotfiles are enabled");
      }
    }

    path = resolvePath(path, root: root, windows: windows);

    if (!await File(path).exists()) {
      throw ArgumentError.value(
          path, "path", "The system cannot find the file specified");
    }

    final file = File(path);

    if (response.headers.contentType == null) {
      final headerBytes = await file.openRead().first;
      final mimeType = mime.lookupMimeType(path, headerBytes: headerBytes)!;
      type(mimeType);
    }

    if (cacheControl) {
      var cacheControl = "max-age=$maxAge";
      if (immutable) cacheControl += ", immutable";
      set("cache-control", cacheControl);
    }

    if (lastModified) {
      final lastModified = (await file.lastModified()).toUtc();
      set("last-modified", lastModifiedFormat(lastModified));
    }

    await stream(file.openRead());
  }

  Future<void> sendStatus(int statusCode) async {
    await status(statusCode)
        .type("txt")
        .send("${response.statusCode} ${response.reasonPhrase}");
  }

  GobiRequest set(String name, Object? value) {
    if (value == null) {
      response.headers.removeAll(name);
    } else {
      response.headers.set(name, value);
    }

    return this;
  }

  GobiRequest status(int statusCode) {
    response.statusCode = statusCode;
    return this;
  }

  Future<void> stream(Stream<List<int>> stream) async {
    await response.addStream(stream);
    await end();
  }

  GobiRequest type(String type, {String? charset = "utf-8"}) {
    var contentType = type.contains("/") ? type : mime.lookupMimeType(type)!;

    if (charset != null) {
      contentType += "; charset=${Uri.encodeComponent(charset)}";
    }

    response.headers.contentType = ContentType.parse(contentType);
    return this;
  }

  GobiRequest vary(String field) {
    return append("vary", field);
  }
}

class GobiServer {
  late final HttpServer httpServer;
  late final GobiMiddleware handler;

  GobiServer(this.handler, ServerSocket serverSocket) {
    httpServer = HttpServer.listenOn(serverSocket)
      ..defaultResponseHeaders.contentType = null;

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
