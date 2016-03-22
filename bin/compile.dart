import 'package:template_cache/cache.dart';
import 'package:glob/glob.dart';
import 'dart:io';

main(List<String> args) {
  if (args.length != 1) {
    return print('Usage: pub run template_cache:compile <glob|filename>');
  }
  final cache = new Cache();
  final glob = new Glob(args[0]);
  glob.list().where((p) => p is File).map((f) => f.path).listen(cache.compile);
}
