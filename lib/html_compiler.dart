import 'dart:io';
import 'cache.dart';
import 'src/simple_compiler_base.dart';

class HtmlCompiler extends Object with SimpleCompilerBase implements Compiler {
  ContentType get contentType => ContentType.HTML;
  Iterable<String> get extensions => ['.html', '.htm'];
}
