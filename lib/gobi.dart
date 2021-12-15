import 'dart:io';

import 'package:gobi/src/handlers.dart';
import 'package:gobi/src/types.dart';

export 'package:gobi/src/types.dart' show GobiResult;

class Gobi extends GobiRoute {
  Gobi() : super("/");

  Future<GobiServer> bind(address, int port) async {
    use((request) async {
      final httpRequest = request.httpRequest;
      final response = httpRequest.response;

      response.statusCode = 404;
      response.reasonPhrase = "Not Found";
      response.headers.contentType = ContentType.text;

      response.write("404 Not Found");

      await response.flush();
      await response.close();

      return GobiResult.close;
    });

    return GobiServer(this, await ServerSocket.bind(address, port));
  }
}
