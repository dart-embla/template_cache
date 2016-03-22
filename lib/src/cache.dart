import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:current_script/current_script.dart';
import 'package:path/path.dart' as path;

import '_gen/templates.dart' as _gen;
import 'cache_io.dart';

export 'dart:io' show ContentType;

final String genDir = path.join(currentScript().parent.path, '_gen');
final Uri templatesDir = new Uri.file(path.join(genDir, 'templates'));
final Uri templatesFile = new Uri.file(path.join(genDir, 'templates.dart'));

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
    final contents = await _templateFileContent(uri).toList().then(_verifyCode);
    await _io.write(
      templateFile,
      new Stream<String>.fromIterable(contents)
    );
    await _io.write(
      templatesFile,
      _templatesFileContent()
    );
  }

  Stream<String> render(Uri file, {Map<Symbol, dynamic> locals: const {}}) {
    final id = _io.uid(file);
    if (_gen.templates.containsKey(id)) {
      throw new Exception('${file.path} is not compiled! Try running "pub run template_cache:compile ${file.path}"');
    }
    return _gen.templates[id](locals).render();
  }

  Stream<String> _makeTemplate(GeneratedTemplateCode code, ContentType contentType) async* {
    yield r"import '../../codegen_contract.dart' as _$_;";
    yield code.directives;
    yield r"class $_ extends _$_.Template {";
    yield "\$_(_) : super('${contentType}', _);";
    yield r"render() async* {";
    yield code.renderBody;
    yield r"}";
    yield r"}";
  }

  Stream<String> _templateFileContent(Uri file) async* {
    final compiler = compilers.firstWhere(
      (c) => c.extensions.any(
        (ex) => file.path.endsWith(ex)
      ), orElse: () => _defaultCompiler
    );
    final read = _io.read(file);
    final code = await compiler.compile(file, read);
    yield* _makeTemplate(code, compiler.contentType);
  }

  String _templateImport(Uri templateUri) {
    final uid = _uidOfUri(templateUri);
    return "import 'templates/$uid.dart' as $uid;";
  }

  String _templateRegistry(Uri templateUri) {
    final uid = _uidOfUri(templateUri);
    return "'$uid': (_) => new $uid.\$_(_),";
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

  Future<List<String>> _verifyCode(List<String> input) async {
    final code = input.join() + r'main() {new $_(null).render();}';
    final tempFile = new File(path.join(templatesDir.path, '_temp${new DateTime.now().millisecondsSinceEpoch}.dart'));
    await tempFile.writeAsString(code);
    final onExit = new ReceivePort();
    final onError = new ReceivePort();
    final errorController = new StreamController();
    onError.listen(errorController.add);
    try {
      await Isolate.spawnUri(
        tempFile.uri,
        null,
        null,
        onExit: onExit.sendPort,
        onError: onError.sendPort,
        automaticPackageResolution: true
      );
      await onExit.first;
      onExit.close();
      onError.close();
      errorController.close();
      final errors = await errorController.stream.toList();
      if (errors.isEmpty) {
        return input;
      }
    } on IsolateSpawnException catch(e) {
      print(e);
    } finally {
      await tempFile.delete();
    }
    final errorGen = new GeneratedTemplateCode(
      '',
      'yield "ERROR";'
    );
    return _makeTemplate(errorGen, ContentType.HTML).toList();
  }
}

abstract class Compiler {
  ContentType get contentType;
  Iterable<String> get extensions;

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source);
}

class GeneratedTemplateCode {
  final String directives;
  final String renderBody;

  GeneratedTemplateCode(this.directives, this.renderBody);
}

class PlainTextCompiler implements Compiler {
  final ContentType contentType = ContentType.TEXT;
  final Iterable<String> extensions = null;

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source) async {
    final content = (await source.join()).replaceAll('"""', '''"""'"""'r"""''');
    return new GeneratedTemplateCode('', 'yield r"""$content""";');
  }
}
