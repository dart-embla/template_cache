import 'dart:async';
import 'dart:io';
import 'dart:convert' show UTF8;
import 'uid.dart' as _uid;

class CacheIo {
  File _file(Uri file) => new File.fromUri(file);

  Stream<String> read(Uri file) => _file(file).openRead().map(UTF8.decode);

  Future<Null> write(Uri file, Stream<String> lines) {
    final openFile = _file(file).openWrite();
    final completer = new Completer();
    lines.listen((s) => openFile.add(UTF8.encode(s)), onDone: () async {
      await openFile.close();
      await completer.complete();
    });
    return completer;
  }

  String uid(Uri file) => _uid.uid(file);

  Future<bool> exists(Uri file) {
    return _file(file).exists();
  }

  Future<DateTime> modifiedAt(Uri file) => _file(file).lastModified();

  Stream<Uri> list(Uri dir) {
    final d = new Directory.fromUri(dir);
    return d.list().where((entity) => entity is File && entity.path.endsWith('.dart'));
  }
}
