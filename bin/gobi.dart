import 'package:gobi/gobi.dart';

void main() {
  gobi.bind("127.0.0.1", 8080);
}

final gobi = Gobi()
  ..route("/static").use(GobiStatic("./public", windows: true));
