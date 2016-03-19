import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:current_script/current_script.dart';

final genDir = path.normalize(path.join(
  currentScript().parent.path,
  '..', // root
  'lib',
  'src',
  '_gen'
));

final templatesDir = path.join(genDir, 'templates');
final templatesFile = path.join(genDir, 'templates.dart');

main() {
  final dir = new Directory(templatesDir);
  dir.deleteSync(recursive: true);
  dir.createSync();

  final file = new File(templatesFile);
  file.writeAsStringSync('final templates = {};');
}
