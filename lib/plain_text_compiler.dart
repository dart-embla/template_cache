import 'dart:io';
import 'cache.dart';
import 'src/simple_compiler_base.dart';

class PlainTextCompiler extends Object with SimpleCompilerBase implements Compiler {
  ContentType get contentType => ContentType.TEXT;
  Iterable<String> get extensions => null;
}
