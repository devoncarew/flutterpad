import 'package:grinder/grinder.dart';

main(List args) => grind(args);

// TODO: update widgets.json

@Task()
generate() => runDartScript('tool/generate.dart');

@Task()
analyze() => new PubApp.global('tuneup').runAsync(['check']);

@Task()
@Depends(generate)
build() => Pub.buildAsync(directories: ['web']);

@Task()
@Depends(build)
deploy() => run('firebase', arguments: ['deploy']);

@DefaultTask()
@Depends(build, analyze)
bot() => null;
