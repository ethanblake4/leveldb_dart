import 'dart:ffi';

import 'package:leveldb_dart/src/leveldb_bindings.dart';
import 'package:meta/meta.dart';

import 'extensions.dart';
import 'library.dart';
import 'native_wrapper.dart';
import 'snapshot.dart';

abstract class ReadOptions extends AnyStructure {
  static final _ReadOptions defaultOptions = _ReadOptions(Lib.levelDB);

  bool get isDefault;
  bool get verifyChecksums;
  bool get fillCache;
  Snapshot? get snapshot;

  factory ReadOptions({
    bool verifyChecksums = _verifyChecksumDefault,
    bool fillCache = _fillCacheDefault,
    Snapshot? snapshot,
  }) =>
      _ReadOptions(
        Lib.levelDB,
        verifyChecksums: verifyChecksums,
        fillCache: fillCache,
        snapshot: snapshot,
      );

  static const _verifyChecksumDefault = false;
  static const _fillCacheDefault = true;

  @protected
  static bool isEqualToDefault({
    bool verifyChecksums = _verifyChecksumDefault,
    bool fillCache = _fillCacheDefault,
    Snapshot? snapshot,
  }) =>
      verifyChecksums == ReadOptions._verifyChecksumDefault &&
      fillCache == ReadOptions._fillCacheDefault &&
      (snapshot == null || snapshot.isDisposed);

  bool operator ==(Object o);
}

class _ReadOptions implements ReadOptions {
  final LibLevelDB lib;
  final bool verifyChecksums;
  final bool fillCache;
  final Snapshot? snapshot;

  @override
  Pointer<leveldb_readoptions_t> ptr;

  @override
  bool get isDefault => ReadOptions.isEqualToDefault(
        verifyChecksums: verifyChecksums,
        fillCache: fillCache,
        snapshot: snapshot,
      );

  _ReadOptions(
    this.lib, {
    this.verifyChecksums = ReadOptions._verifyChecksumDefault,
    this.fillCache = ReadOptions._fillCacheDefault,
    this.snapshot,
  }) : ptr = _setup(
          lib,
          verifyChecksums: verifyChecksums,
          fillCache: fillCache,
          snapshot: snapshot,
        );

  static Pointer<leveldb_readoptions_t> _setup(
    LibLevelDB lib, {
    bool? verifyChecksums,
    bool? fillCache,
    Snapshot? snapshot,
  }) {
    final ptr = lib.leveldb_readoptions_create();
    lib.leveldb_readoptions_set_fill_cache(ptr, fillCache?.toInt() ?? 0);
    lib.leveldb_readoptions_set_verify_checksums(
        ptr, verifyChecksums?.toInt() ?? 0);
    if (snapshot == null || snapshot.isDisposed) {
      lib.leveldb_readoptions_set_snapshot(ptr, nullptr);
    } else {
      lib.leveldb_readoptions_set_snapshot(
          ptr, snapshot.ptr as Pointer<leveldb_snapshot_t>);
    }
    return ptr;
  }

  @override
  void dispose() {
    if (isDisposed) return;
    lib.leveldb_readoptions_destroy(ptr);
    ptr == nullptr;
    // TODO: print friendly reminder, Snapshot is not disposed.
  }

  @override
  String toString() {
    return '_ReadOptions verifyChecksums: $verifyChecksums, fillCache: $fillCache, snapshot: $snapshot, ptr: $ptr';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is _ReadOptions &&
        o.lib == lib &&
        o.verifyChecksums == verifyChecksums &&
        o.fillCache == fillCache &&
        o.snapshot == snapshot &&
        o.ptr == ptr;
  }

  @override
  int get hashCode {
    return lib.hashCode ^
        verifyChecksums.hashCode ^
        fillCache.hashCode ^
        snapshot.hashCode ^
        ptr.hashCode;
  }
}
