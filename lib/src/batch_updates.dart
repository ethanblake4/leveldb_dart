import 'dart:ffi';

import 'package:leveldb_dart/src/leveldb_bindings.dart';

import 'extensions.dart';
import 'library.dart';
import 'native_wrapper.dart';
import 'raw_data.dart';

/// [BatchUpdates] holds a collection of updates to apply atomically to a DB.
///
/// The updates are applied in the order in which they are added
/// to the [BatchUpdates].  For example, the value of [key] will be "v3"
/// after the following batch is written:
///
///    batch.Put("key", "v1");
///    batch.Delete("key");
///    batch.Put("key", "v2");
///    batch.Put("key", "v3");
///
/// Multiple threads can invoke const methods on a [BatchUpdates] without
/// external synchronization, but if any of the threads may call a
/// non-const method, all threads accessing the same [BatchUpdates] must use
/// external synchronization.
abstract class BatchUpdates extends AnyStructure {
  /// Store the mapping "key->value" in the database.
  /// throws [StateError] if method was called after [BatchUpdates.dispose]
  void put(RawData key, RawData value);

  /// Copies the operations in "source" to this batch.
  /// throws [StateError] if method was called after [BatchUpdates.dispose]
  void append(BatchUpdates updates);

  /// If the database contains a mapping for [key], erase it.  Else do nothing.
  /// throws [StateError] if method was called after [BatchUpdates.dispose]
  void delete(RawData key);

  /// Clear all updates buffered in this batch.
  void clear();

  void operator +(BatchUpdates obj);

  factory BatchUpdates() => _BatchUpdates(Lib.levelDB);
}

class _BatchUpdates implements BatchUpdates {
  final LibLevelDB lib;

  @override
  Pointer<leveldb_writebatch_t> ptr;

  _BatchUpdates(this.lib) : ptr = lib.leveldb_writebatch_create();

  @override
  void operator +(BatchUpdates obj) {
    return append(obj);
  }

  @override
  void append(BatchUpdates updates) {
    attemptTo('append');
    updates.attemptTo('append');

    lib.leveldb_writebatch_append(
        ptr, updates.ptr as Pointer<leveldb_writebatch_t>);
  }

  @override
  void put(RawData key, RawData value) {
    attemptTo('put');

    return lib.leveldb_writebatch_put(
      ptr,
      key.ptr.cast(),
      key.length,
      value.ptr.cast(),
      value.length,
    );
  }

  @override
  void delete(RawData key) {
    attemptTo('delete');

    return lib.leveldb_writebatch_delete(ptr, key.ptr.cast(), key.length);
  }

  @override
  void clear() {
    if (isDisposed) return;

    lib.leveldb_writebatch_clear(ptr);
  }

  @override
  void dispose() {
    if (isDisposed) return;

    lib.leveldb_writebatch_destroy(ptr);
  }
}
