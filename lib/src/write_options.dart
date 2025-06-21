import 'dart:ffi';

import 'package:leveldb_dart/src/leveldb_bindings.dart';
import 'extensions.dart';
import 'library.dart';
import 'native_wrapper.dart';

abstract class WriteOptions extends AnyStructure {
  bool get isSync;
  static final WriteOptions sync = _WriteOptions(Lib.levelDB, true);
  static final WriteOptions noSync = _WriteOptions(Lib.levelDB, false);
}

class _WriteOptions implements WriteOptions {
  final LibLevelDB lib;
  final bool isSync;
  _WriteOptions(this.lib, this.isSync)
      : ptr = lib.leveldbWriteOptionsCreateWithSync(isSync);

  @override
  void dispose() {
    if (isDisposed) return;
    lib.leveldb_writeoptions_destroy(ptr);
    ptr = nullptr;
  }

  @override
  Pointer<leveldb_writeoptions_t> ptr;
}

extension on LibLevelDB {
  Pointer<leveldb_writeoptions_t> leveldbWriteOptionsCreateWithSync(
    bool isSync,
  ) {
    final writeOptions = leveldb_writeoptions_create();
    leveldb_writeoptions_set_sync(writeOptions, isSync ? 1 : 0);
    return writeOptions;
  }
}
