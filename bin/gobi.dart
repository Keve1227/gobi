import 'package:gobi/gobi.dart';

void main() {
  gobi.bind("127.0.0.1", 8080);
}

final gobi = Gobi()
  ..route("/:path").get((request) async {
    await request.sendFile("test.jpg", root: "./public");
  });
