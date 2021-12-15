import 'package:gobi/gobi.dart';

final gobi = Gobi()
  ..route("/:path").get((request) async {
    final httpRequest = request.httpRequest;
    final response = httpRequest.response;

    response.write(request.params["path"]);

    await response.flush();
    await response.close();

    return GobiResult.close;
  });

void main() {
  gobi.bind("127.0.0.1", 8080);
}
