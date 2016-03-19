import 'dart:convert' show BASE64;

String uid(Uri file) => 'template_' + BASE64
  .encode(file.path.codeUnits)
  .replaceAll('=', '_');
