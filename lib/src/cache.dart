import 'dart:async';
import 'dart:io';

import 'cache_io.dart';
import '_gen/templates.dart' as _gen;
import 'package:current_script/current_script.dart';
import 'package:path/path.dart' as path;

export 'dart:io' show ContentType;

final String genDir = path.join(currentScript().parent.path, '_gen');
final Uri templatesFile = new Uri.file(path.join(genDir, 'templates.dart'));
final Uri templatesDir = new Uri.file(path.join(genDir, 'templates'));

class Cache {
  final CacheIo _io;
  final Iterable<Compiler> compilers;
  final _defaultCompiler = new PlainTextCompiler();

  Cache([
    Iterable<Compiler> this.compilers = const [],
    CacheIo io
  ]) : _io = io ?? new CacheIo();

  Future<Null> compile(String file) async {
    final uri = new Uri.file(file);
    final uid = _io.uid(uri);
    final templateFile = new Uri.file(path.join(genDir, 'templates', '$uid.dart'));

    await _io.write(
      templateFile,
      _templateFileContent(uri)
    );
    await _io.write(
      templatesFile,
      _templatesFileContent()
    );
  }

  Stream<String> render(Uri file, {Map<Symbol, dynamic> locals: const {}}) {
    return _gen.templates[_io.uid(file)](locals).render();
  }

  Stream<String> _templateFileContent(Uri file) async* {
    final compiler = compilers.firstWhere(
      (c) => c.extensions.any(
        (ex) => file.path.endsWith(ex)
      ), orElse: () => _defaultCompiler
    );
    final read = _io.read(file);
    final code = await compiler.compile(file, read);
    yield r"import '../../codegen_contract.dart' as _$_;";
    yield code.directives;
    yield r"class $_ extends _$_.Template {";
    yield "\$_(_) : super('${compiler.contentType}', _);";
    yield r"render() async* {";
    yield code.renderBody;
    yield r"}";
    yield r"}";

  }

  Stream<String> _templatesFileContent() async* {
    final allFiles = await _io.list(templatesDir).toList();
    yield "import '../codegen_contract.dart';";
    yield* new Stream.fromIterable(allFiles.map(_templateImport));
    yield "final Map<String, TemplateFactory> templates = {";
    yield* new Stream.fromIterable(allFiles.map(_templateRegistry));
    yield "};";
  }

  String _uidOfUri(Uri uri) => path.split(uri.path).last.replaceFirst('.dart', '');

  String _templateRegistry(Uri templateUri) {
    final uid = _uidOfUri(templateUri);
    return "'$uid': (_) => new $uid.\$_(_),";
  }

  String _templateImport(Uri templateUri) {
    final uid = _uidOfUri(templateUri);
    return "import 'templates/$uid.dart' as $uid;";
  }
}

class GeneratedTemplateCode {
  final String directives;
  final String renderBody;

  GeneratedTemplateCode(this.directives, this.renderBody);
}

abstract class Compiler {
  Iterable<String> get extensions;
  ContentType get contentType;

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source);
}

class PlainTextCompiler implements Compiler {
  final ContentType contentType = ContentType.TEXT;
  final Iterable<String> extensions = null;

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source) async {
    final content = (await source.join()).replaceAll('"""', '''"""'"""'r"""''');
    return new GeneratedTemplateCode('', 'yield r"""$content""";');
  }
}
