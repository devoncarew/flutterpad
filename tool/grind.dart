import 'dart:convert' show UTF8;
import 'dart:io';

import 'package:grinder/grinder.dart';

main(List<String> args) => grind(args);

@Task()
generate() => Dart.runAsync('tool/generate.dart');

@Task()
analyze() => new PubApp.global('tuneup').runAsync(['check']);

@Task()
@Depends(generate)
build() => Pub.buildAsync(directories: ['web']);

@Task()
@Depends(build)
deploy() => runAsync('firebase', arguments: ['deploy']);

@DefaultTask()
@Depends(build, analyze)
bot() => null;

@Task()
updateWidgets() {
  final String url = 'https://raw.githubusercontent.com/devoncarew/type_hierarchy/master/widgets.json';
  final String path = 'tool/widgets.json';

  HttpClient client = new HttpClient();
  return client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
    return request.close();
  }).then((HttpClientResponse response) {
    return response.transform(UTF8.decoder).toList();
  }).then((List data) {
    String contents = data.join('');
    getFile(path).writeAsStringSync(contents);
  });
}
