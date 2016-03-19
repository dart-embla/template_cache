import 'package:template_cache/cache.dart';

main(List<String> args) {
  if (args.length != 1) {
    return print('Usage: pub run template_cache:compile my_template_file.html');
  }
  final cache = new Cache();
  cache.compile(args[0]);
}
