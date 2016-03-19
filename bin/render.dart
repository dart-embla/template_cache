import 'package:template_cache/render.dart';

main(List<String> args) {
  if (args.length != 1) {
    return print('Usage: pub run template_cache:render my_template_file.html');
  }
  render(args[0]).join().then(print);
}
