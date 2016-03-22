import 'package:template_cache/render.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

main(List<String> args) {
  if (args.length != 1) {
    return print('Usage: pub run template_cache:render my_template_file.html');
  }
  render(path.join(Directory.current.path, args[0]));
}
