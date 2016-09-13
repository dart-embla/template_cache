import 'dart:async';

import 'package:quark/quark.dart';
export 'package:quark/init.dart';

import 'package:template_cache/plain_text_compiler.dart';

class PlainTextCompilerTest extends UnitTest {
  PlainTextCompiler compiler;

  @before
  setUp() {
    compiler = new PlainTextCompiler();
  }

  @test
  itDoesNothingToTheInput() async {
    await _assertCompiles(() async* {
      yield 'line';
      yield 'line2';
    }, [
      'yield r"""line""";',
      'yield r"""line2""";',
    ]);
  }

  @test
  itEscapesTripleQuotes() async {
    await _assertCompiles(() async* {
      yield 'a"""b';
    }, [
      'yield r"""a"""\'"""\'r"""b""";',
    ]);
  }

  _assertCompiles(Stream<String> generator(), Iterable<String> expectedLines) async {
    final result = await compiler.compile(new Uri.file('x.txt'), generator());

    expect(result.renderBody, expectedLines.join('\n'));
  }
}
