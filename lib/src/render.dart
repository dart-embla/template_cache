import '_gen/templates.dart' as _gen;
import 'uid.dart';
import 'dart:async';
import 'codegen_contract.dart' show Template;
export 'codegen_contract.dart' show Template;

Stream<String> render(String file, {Map<Symbol, dynamic> locals: const {}}) {
  // Indirection to make sure output stream is instance of
  // [Stream<String>] and not [Stream<dynamic>].
  final controller = new StreamController<String>();
  view(file, locals: locals).render().pipe(controller);
  return controller.stream;
}

Template view(String file, {Map<Symbol, dynamic> locals: const {}}) {
  final id = uid(new Uri.file(file));
  if (!_gen.templates.containsKey(id)) {
    throw new Exception('$file is not compiled! Try running "pub run template_cache:compile $file"');
  }
  return _gen.templates[id](locals);
}
