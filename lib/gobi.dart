import 'dart:io';

import 'package:gobi/src/handlers.dart';
import 'package:gobi/src/types.dart';

export 'package:gobi/src/types.dart' show GobiResult;

class Gobi extends GobiRoute {
  Gobi() : super("/");

  Future<GobiServer> bind(address, int port) async {
    use((request) async => request.sendStatus(404));

    return GobiServer(this, await ServerSocket.bind(address, port));
  }
}
