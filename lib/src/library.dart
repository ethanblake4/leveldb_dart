import 'dart:ffi';
import 'dart:io';

import 'package:leveldb_dart/src/leveldb_bindings.dart';

abstract class Lib {
  /// lazy static var
  static bool _isInitialized = false;
  static late final LibLevelDB levelDB;

  static LibLevelDB loadLevelDB(String? dlpath) {
    if (_isInitialized) {
      return levelDB;
    }
    if (dlpath != null) {
      return levelDB = LibLevelDB(DynamicLibrary.open(dlpath));
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return levelDB = LibLevelDB(DynamicLibrary.process());
    }
    final dlExtension = Platform.isWindows ? '.dll' : '.so';
    return levelDB = LibLevelDB(DynamicLibrary.open('libleveldb.$dlExtension'));
  }
}
