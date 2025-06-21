import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:leveldb_dart/src/leveldb_bindings.dart';
import 'package:leveldb_dart/src/write_options.dart';

import 'batch_updates.dart';
import 'extensions.dart';
import 'iterator.dart';
import 'library.dart';
import 'native_wrapper.dart';
import 'options.dart';
import 'raw_data.dart';
import 'read_options.dart';
import 'snapshot.dart';
import 'utils.dart';

abstract class LevelDB {
  static init(String? libraryPath) {
    Lib.loadLevelDB(libraryPath);
  }

  /// Open the database with the specified [filePath].
  factory LevelDB.open({
    required Options options,
    required String filePath,
  }) {
    assert(
      filePath.isNotEmpty,
      'LevelDB.open: "filePath" parameter is required',
    );
    return _LevelDB.open(
      Lib.levelDB,
      options: options,
      name: filePath,
    );
  }

  factory LevelDB.pointer({
    String? libraryPath,
    required Pointer<leveldb_t> pointer,
    required Options options,
  }) {
    return _LevelDB.ptr(
      Lib.levelDB,
      options: options,
      ptr: pointer,
    );
  }

  /// If a DB cannot be opened, you may attempt to call this method to
  /// resurrect as much of the contents of the database as possible.
  /// Some data may be lost, so be careful when calling this function
  /// on a database that contains important information.
  ///
  /// throws [LevelDBException]
  static void repair(String filePath, Options options) {
    return _SLevelDB.repair(filePath, options);
  }

  /// Destroy the contents of the specified database.
  /// Be very careful using this method.
  ///
  /// Note: For backwards compatibility, if DestroyDB is unable to list the
  /// database files, Status::OK() will still be returned masking this failure.
  ///
  /// throws [LevelDBException]
  static void destroy(String filePath, Options options) {
    return _SLevelDB.destroy(filePath, options);
  }

  ///
  /// Close leveldb, release any pointer
  ///
  void close();

  void free(RawData data);

  /// Returns the corresponding value for [key]
  ///
  /// **[verifyChecksums]**: If true, all data read from underlying
  /// storage will be verified against corresponding checksums.
  ///
  /// **[fillCache]**: Should the data read for this iteration be cached in memory?
  /// Callers may wish to set this field to false for bulk scans.
  ///
  /// **[snapshot]**: If is non-null, read as of the supplied snapshot
  /// (which must belong to the DB that is being read and which must
  /// not have been released).  If [snapshot] is null, use an implicit
  /// snapshot of the state at the beginning of this read operation.
  RawData get(
    RawData key, {
    bool verifyChecksums = false,
    bool fillCache = true,
    Snapshot? snapshot,
  });

  /// Return an iterator over the contents of the database.
  /// Caller should [dispose] the iterator when it is no longer needed.
  /// The returned iterator should be disposed before this db is disposed.
  ///
  /// **[verifyChecksums]**: If true, all data read from underlying
  /// storage will be verified against corresponding checksums.
  ///
  /// **[fillCache]**: Should the data read for this iteration be cached in memory?
  /// Callers may wish to set this field to false for bulk scans.
  ///
  /// **[snapshot]**: If is non-null, read as of the supplied snapshot
  /// (which must belong to the DB that is being read and which must
  /// not have been released).  If [snapshot] is null, use an implicit
  /// snapshot of the state at the beginning of this read operation.
  DBIterator iterator({
    bool verifyChecksums = false,
    bool fillCache = true,
    Snapshot snapshot,
  });

  /// Set the database entry for [key] to [value].
  ///
  /// If [ensured] == true, the write will be flushed from the operating system
  /// buffer cache before the write is considered complete.
  /// If this flag is true, writes will be slower.
  ///
  /// If this flag is false, and the machine crashes, some recent
  /// writes may be lost.  Note that if it is just the process that
  /// crashes (i.e., the machine does not reboot), no writes will be
  /// lost even if [ensured] == false.
  ///
  /// In other words, a DB write with [ensured] == false has similar
  /// crash semantics as the "write()" system call.  A DB write
  /// with [ensured] == true has similar crash semantics to a "write()"
  /// system call followed by "fsync()".
  void put(RawData key, RawData value, {bool ensured = false});

  /// Set the database entry for [key] to [value].
  ///
  /// If [ensured] == true, the write will be flushed from the operating system
  /// buffer cache before the write is considered complete.
  /// If this flag is true, writes will be slower.
  /// If this flag is false, and the machine crashes, some recent
  /// writes may be lost.
  void delete(RawData key, {bool ensured = false});

  /// Apply the specified updates to the database.
  ///
  /// If [ensured] == true, the write will be flushed from the operating system
  /// buffer cache before the write is considered complete.
  /// If this flag is true, writes will be slower.
  /// If this flag is false, and the machine crashes, some recent
  /// writes may be lost.
  void write(BatchUpdates updates, {bool ensured = false});

  /// Return a handle to the current DB state.  Iterators created with
  /// this handle will all observe a stable snapshot of the current DB
  /// state.  The caller must call [Snapshot.dispose] when the
  /// snapshot is no longer needed.
  Snapshot getSnapshot();

  /// Compact the underlying storage for the key range [*begin,*end].
  /// In particular, deleted and overwritten versions are discarded,
  /// and the data is rearranged to reduce the cost of operations
  /// needed to access the data.  This operation should typically only
  /// be invoked by users who understand the underlying implementation.
  ///
  /// [beginKey] == null is treated as a key before all keys in the database.
  /// [endKey] == null is treated as a key after all keys in the database.
  /// Therefore the following call will compact the entire database:
  /// [LevelDB.compact(null, null)]
  void compact(RawData beginKey, RawData endKey);

  // --- Statistics ---

  /// Number of files at level
  int numFilesAtLevel(int level);

  /// returns a multi-line string that describes statistics
  /// about the internal operation of the DB
  String stats();

  /// returns a multi-line string that describes all
  /// of the sstables that make up the db contents.
  String sstables();

  /// returns the approximate number of
  /// bytes of memory in use by the DB.
  int approximateMemoryUsage();
}

abstract class _Properties {
  static const num_files_at_level = 'leveldb.num-files-at-level<N>';
  static const stats = 'leveldb.stats';
  static const sstables = 'leveldb.sstables';
  static const approximate_memory_usage = 'leveldb.approximate-memory-usage';
}

extension _SLevelDB on _LevelDB {
  static void repair(String filePath, Options options) {
    return errorHandler((errPtr) {
      return allocctx((strPtr) {
        // ignore: invalid_use_of_protected_member
        return Lib.levelDB.leveldb_repair_db(
            options.ptr as Pointer<leveldb_options_t>, strPtr, errPtr);
      }, () => filePath.toNativeUtf8().cast<Char>());
    });
  }

  static void destroy(String filePath, Options options) {
    return errorHandler((errPtr) {
      return allocctx((strPtr) {
        // ignore: invalid_use_of_protected_member
        return Lib.levelDB.leveldb_destroy_db(
            options.ptr as Pointer<leveldb_options_t>, strPtr.cast(), errPtr);
      }, () => filePath.toNativeUtf8());
    });
  }
}

class _LevelDB extends DisposablePointer<leveldb_t> implements LevelDB {
  final LibLevelDB lib;
  final Options options;

  @override
  Pointer<leveldb_t> ptr;

  _LevelDB.open(
    this.lib, {
    required this.options,
    required String name,
  }) : ptr = _open(options, name, lib);

  _LevelDB.ptr(
    this.lib, {
    required this.ptr,
    required this.options,
  });

  static Pointer<leveldb_t> _open(
    Options options,
    String name,
    LibLevelDB lib,
  ) {
    return allocctx((Pointer<Utf8> strptr) {
      return errorHandler(
        // ignore: invalid_use_of_protected_member
        (errptr) => lib.leveldb_open(
            options.ptr as Pointer<leveldb_options_t>, strptr.cast(), errptr),
      );
    }, () => name.toNativeUtf8());
  }

  @override
  void close() {
    lib.leveldb_close(ptr); // close db before dispose
  }

  @override
  void dispose() {
    if (isDisposed) return;
    calloc.free(ptr);
    ptr = nullptr;
    options.dispose();
  }

  @override
  void delete(RawData key, {bool ensured = false}) {
    assert(!key.isDisposed, 'Key is empty');
    attemptTo('delete');

    return errorHandler((errPtr) => lib.leveldb_delete(
          ptr,
          ensured
              ? WriteOptions.sync.ptr as Pointer<leveldb_writeoptions_t>
              : WriteOptions.noSync.ptr as Pointer<leveldb_writeoptions_t>,
          key.ptr.cast(),
          key.length,
          errPtr,
        ));
  }

  @override
  RawData get(
    RawData key, {
    bool verifyChecksums = false,
    bool fillCache = true,
    Snapshot? snapshot,
  }) {
    assert(!key.isDisposed, 'Key is empty');
    attemptTo('get');
    // ignore: invalid_use_of_protected_member
    final readOptionsAreDefault = ReadOptions.isEqualToDefault(
      verifyChecksums: verifyChecksums,
      fillCache: fillCache,
      snapshot: snapshot,
    );

    RawData exec(ReadOptions readOptions) {
      int valLength = 0;
      final rawDataPtr = allocctx((Pointer<Size> vallen) {
        final result = errorHandler((errptr) {
          return lib.leveldb_get(
            ptr,
            ReadOptions.defaultOptions.ptr,
            key.ptr.cast(),
            key.length,
            vallen,
            errptr,
          );
        });
        if (vallen != nullptr) {
          valLength = vallen.value;
        }

        return result;
      });

      return RawData.native(rawDataPtr.cast(), valLength);
    }

    if (readOptionsAreDefault) {
      return exec(ReadOptions.defaultOptions);
    } else {
      final options = ReadOptions(
        fillCache: fillCache,
        verifyChecksums: verifyChecksums,
        snapshot: snapshot,
      );
      final result = exec(options);
      options.dispose();
      return result;
    }
  }

  @override
  void free(RawData data) {
    assert(!data.isDisposed, 'Data is empty');
    attemptTo('free');
    return lib.leveldb_free(data.ptr.cast());
  }

  DBIterator exec(ReadOptions readOptions,
      {Position<RawData> initialPosition = const Position.first()}) {
    return DBIterator.atPosition(
      dbptr: lib.leveldb_create_iterator(
          ptr, readOptions.ptr as Pointer<leveldb_readoptions_t>),
      initialPosition: initialPosition,
    );
  }

  @override
  DBIterator iterator({
    bool verifyChecksums = false,
    bool fillCache = true,
    Snapshot? snapshot,
    Position<RawData> initialPosition = const Position.first(),
  }) {
    attemptTo('iterator');
    // ignore: invalid_use_of_protected_member
    final readOptionsAreDefault = ReadOptions.isEqualToDefault(
      verifyChecksums: verifyChecksums,
      fillCache: fillCache,
      snapshot: snapshot,
    );

    if (readOptionsAreDefault) {
      return exec(ReadOptions.defaultOptions, initialPosition: initialPosition);
    } else {
      final options = ReadOptions(
        fillCache: fillCache,
        verifyChecksums: verifyChecksums,
        snapshot: snapshot,
      );
      final result = exec(options);
      options.dispose();
      return result;
    }
  }

  @override
  void put(RawData key, RawData value, {bool ensured = false}) {
    assert(!key.isDisposed, 'Key is empty');
    assert(!value.isDisposed, 'Value is empty');
    return errorHandler((errPtr) {
      return lib.leveldb_put(
        ptr,
        ensured
            ? WriteOptions.sync.ptr as Pointer<leveldb_writeoptions_t>
            : WriteOptions.noSync.ptr as Pointer<leveldb_writeoptions_t>,
        key.ptr.cast(),
        key.length,
        value.ptr.cast(),
        value.length,
        errPtr,
      );
    });
  }

  @override
  void write(BatchUpdates updates, {bool ensured = false}) {
    final _updatesAreValid = !(updates.isDisposed);
    assert(_updatesAreValid, 'updates is null or disposed');
    if (!_updatesAreValid) return;

    return errorHandler((errPtr) {
      return lib.leveldb_write(
        ptr,
        ensured
            ? WriteOptions.sync.ptr as Pointer<leveldb_writeoptions_t>
            : WriteOptions.noSync.ptr as Pointer<leveldb_writeoptions_t>,
        updates.ptr as Pointer<leveldb_writebatch_t>,
        errPtr,
      );
    });
  }

  @override
  Snapshot getSnapshot() {
    attemptTo('getSnapshot');
    return _Snapshot(lib, ptr);
  }

  @override
  void compact(RawData beginKey, RawData endKey) {
    attemptTo('compact');
    return lib.leveldb_compact_range(
      ptr,
      beginKey.ptr.cast(),
      beginKey.length,
      endKey.ptr.cast(),
      endKey.length,
    );
  }

  String _getProperty(String prop) {
    final str = allocctx((strPtr) {
      return lib.leveldb_property_value(ptr, strPtr.cast());
    }, () => prop.toNativeUtf8());
    final result = str.cast<Utf8>().toDartString();
    calloc.free(str);
    return result;
  }

  @override
  int approximateMemoryUsage() {
    attemptTo('approximateMemoryUsage');
    return int.tryParse(
          _getProperty(_Properties.approximate_memory_usage),
        ) ??
        0;
  }

  @override
  int numFilesAtLevel(int level) {
    attemptTo('numFilesAtLevel');
    return int.tryParse(
          _getProperty(_Properties.num_files_at_level),
        ) ??
        0;
  }

  @override
  String sstables() {
    attemptTo('sstables');
    return _getProperty(_Properties.sstables);
  }

  @override
  String stats() {
    attemptTo('stats');
    return _getProperty(_Properties.stats);
  }
}

class _Snapshot implements Snapshot {
  final LibLevelDB lib;

  Pointer<leveldb_t> dbptr;

  @override
  Pointer<leveldb_snapshot_t> ptr;

  _Snapshot(this.lib, this.dbptr) : ptr = lib.leveldb_create_snapshot(dbptr);

  @override
  void dispose() {
    if (isDisposed) return;
    if (dbptr == nullptr) {
      throw StateError('Attempt to [Snapshot.dispose] after [LevelDB.dispose]');
    }
    lib.leveldb_release_snapshot(dbptr, ptr);
    ptr = nullptr;
    dbptr = nullptr;
  }
}
