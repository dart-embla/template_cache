import '_gen/templates.dart' as _gen;
import 'uid.dart';
import 'dart:async';
import 'codegen_contract.dart' show Template;
export 'codegen_contract.dart' show Template;

Stream<String> render(String file, {Map<Symbol, dynamic> locals: const {}}) {
  return view(file, locals: locals).render();
}

Template view(String file, {Map<Symbol, dynamic> locals: const {}}) {
  final id = uid(new Uri.file(file));
  print(_gen.templates);
  print(id);
  return _gen.templates[id](locals);
}
