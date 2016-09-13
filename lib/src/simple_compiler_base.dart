import 'dart:io';
import 'dart:async';
import 'cache.dart';

abstract class SimpleCompilerBase implements Compiler {
  Future<GeneratedTemplateCode> compile(Uri file, Stream<String> source) async {
    return new GeneratedTemplateCode(
        '',
        await source
          .map(_escapeTripleQuote)
          .map(_wrapLine)
          .join('\n')
    );
  }

  /// Effectively replaces a triple quote with a closing
  /// triple quote, followed by the string """ wrapped in
  /// single quotes, followed by opening raw triple quotes.
  ///
  ///     --> """
  ///     <-- """  '"""'  r"""
  String _escapeTripleQuote(String input) {
    return input.replaceAll('"""', '''"""'"""'r"""''');
  }

  String _wrapLine(String line) {
    return 'yield r"""$line""";';
  }
}
