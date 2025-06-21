import 'dart:ffi';

import 'package:leveldb_dart/src/leveldb_bindings.dart';
import 'package:meta/meta.dart';

import 'extensions.dart';
import 'library.dart';
import 'native_wrapper.dart';

typedef comparator_destructor = Void Function(Pointer<Void>);
typedef comparator_compare = Int Function(
  Pointer<Void>,
  Pointer<Char>,
  Size,
  Pointer<Char>,
  Size,
);
typedef comparator_name = Pointer<Char> Function(Pointer<Void>);

// !: [Pointer.fromFunction] returned function address can only be invoked on the mutator (main)
// !: thread of the current isolate. It will abort the process if invoked on any
// !: other thread.
// TODO: testing is required
/// A Comparator object provides a total order across slices that are
/// used as keys in an sstable or a database.  A Comparator implementation
/// must be thread-safe since leveldb may invoke its methods concurrently
/// from multiple threads.
@experimental
abstract class Comparator extends AnyStructure {
  factory Comparator({
    required Pointer<Void> state,
    required Pointer<NativeFunction<comparator_destructor>> destructor,
    required Pointer<NativeFunction<comparator_compare>> compare,
    required Pointer<NativeFunction<comparator_name>> name,
  }) {
    return _Comparator(
      Lib.levelDB,
      state: state,
      destructor: destructor,
      compare: compare,
      name: name,
    );
  }
}

class _Comparator implements Comparator {
  final LibLevelDB _lib;

  _Comparator(
    this._lib, {
    required Pointer<Void> state,
    required Pointer<NativeFunction<comparator_destructor>> destructor,
    required Pointer<NativeFunction<comparator_compare>> compare,
    required Pointer<NativeFunction<comparator_name>> name,
  }) : ptr = _lib.leveldb_comparator_create(
          state,
          destructor,
          compare,
          name,
        );

  @override
  Pointer<leveldb_comparator_t> ptr;

  @override
  void dispose() {
    if (isDisposed) return;
    _lib.leveldb_comparator_destroy(ptr);
    ptr = nullptr;
  }
}
