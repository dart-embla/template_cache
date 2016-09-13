import 'dart:async';

import 'package:quark/quark.dart';
export 'package:quark/init.dart';

import 'package:template_cache/cache.dart';
import 'package:path/path.dart' as path;

class CacheTest extends UnitTest {
  TestIo io;
  Cache cache;

  @before
  setUp() {
    cache = new Cache([
      new XCompiler(),
      new YCompiler()
    ], io = new TestIo());
  }

  @test
  itCompilesTemplatesWithAPlainTextCompiler() async {
    cache = new Cache([], io = new TestIo());

    io.files[new Uri.file('x')] = ['x"""y'];
    await cache.compile('x');
    expect(io.newFiles.length, 2);
    expect(io.newFiles[templatesFile], [
      "import '../codegen_contract.dart';",
      "import 'templates/UID.dart' as UID;",
      "final Map<String, TemplateFactory> templates = {",
      r"'UID': (_) => new UID.$_(_),",
      "};"
    ]);
    final generatedFile = new Uri.file(path.join(genDir, 'templates', 'UID.dart'));
    expect(io.newFiles[generatedFile], [
      "import 'dart:async';",
      r"import '../../codegen_contract.dart' as _$_;",
      r'',
      r"class $_ extends _$_.Template {",
      r"$_(_) : super('text/plain; charset=utf-8', _);",
      r"Stream<String> render() async* {",
      r'''yield r"""x"""'"""'r"""y""";''',
      r"}",
      r"}"
    ]);
  }

  expectCompiles(String file, String contents, matcher) async {
    io.files[new Uri.file(file)] = [contents];
    await cache.compile(file);
    final generatedFile = new Uri.file(path.join(genDir, 'templates', 'UID.dart'));
    expect(io.newFiles[generatedFile], matcher);
  }

  @test
  itChoosesTheCompilerThatHasTheExtension() async {
    await expectCompiles('x.x', '', contains('yield "X";'));
    await expectCompiles('y.y', '', contains('yield "Y";'));
    await expectCompiles('z.z', 'z', contains('yield r"""z""";'));
  }

  @test
  itRendersAnErrorPageIfTheOutputIsInvalidDartCode() async {
    cache = new Cache([new BrokenCompiler()], io);
    await expectCompiles('foo.broken', '', contains('yield "ERROR";'));
  }
}

class XCompiler implements Compiler {
  final extensions = ['.x'];
  final contentType = ContentType.TEXT;

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source) async {
    return new GeneratedTemplateCode(
      '',
      'yield "X";'
    );
  }
}

class YCompiler implements Compiler {
  final extensions = ['.y'];
  final contentType = ContentType.TEXT;

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source) async {
    return new GeneratedTemplateCode(
      '',
      'yield "Y";'
    );
  }
}

class BrokenCompiler implements Compiler {
  final extensions = ['.broken'];
  final contentType = ContentType.TEXT;

  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source) async {
    return new GeneratedTemplateCode(
      '',
      'invalid dart code'
    );
  }
}

class TestIo implements CacheIo {
  final Map<Uri, List<String>> files = {};
  final Map<Uri, DateTime> modifications = {};
  final Map<Uri, List<String>> newFiles = {};

  Stream<String> read(Uri file) {
    return new Stream<String>.fromIterable(files[file]);
  }

  Future<Null> write(Uri file, Stream<String> lines) async {
    newFiles[file] = files[file] = await lines.toList();
  }

  Future<bool> exists(Uri file) async => files.containsKey(file);

  Future<DateTime> modifiedAt(Uri file) async => modifications[file];

  String uid(Uri file) => 'UID';

  Stream<Uri> list(Uri dir) => new Stream<Uri>.fromIterable([new Uri.file('UID.dart')]);
}
