import 'dart:io';

import 'package:leveldb_dart/leveldb_dart.dart';

void main() {
  String? libPath;
  if (Platform.isWindows) {
    libPath = r'..\leveldb\Debug\leveldb.dll';
  } else if (Platform.isLinux || Platform.isAndroid) {
    libPath = r'../leveldb/libleveldb.so';
  } else if (Platform.isMacOS) {
    libPath = r'../leveldb/libleveldb.dylib';
  }

  LevelDB.init(libPath);

  final dbPath = 'example.leveldb';
  final db = LevelDB.open(
    options: Options.byDefault(createIfMissing: true),
    filePath: dbPath,
  );

  void put() {
    final k = RawData.fromString('example');
    final v = RawData.fromString('world');
    db.put(k, v, ensured: true);
    k.dispose();
    v.dispose();
  }

  String get() {
    final k = RawData.fromString('example');
    final v = db.get(k);
    final result = String.fromCharCodes(v.bytes);
    k.dispose();
    db.free(v);
    return result;
  }

  put();
  final str = get();
  print(str);
}
