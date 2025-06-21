import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:leveldb_dart/src/extensions.dart';

import 'native_wrapper.dart';

/// byte array wrapper
abstract class RawData extends DisposablePointer<Uint8> {
  int get length;
  Uint8List get bytes;

  factory RawData.native(Pointer<Uint8> pointer, int length) =>
      _RawData.native(pointer, length);

  factory RawData.fromString(String str) {
    final bytes = str.toNativeUtf8(allocator: calloc);
    return _RawData.native(bytes.cast<Uint8>(), bytes.length);
  }

  factory RawData.fromList(Uint8List bytes) => _RawData.fromList(bytes);
}

/// TODO: https://github.com/dart-lang/sdk/issues/35763
class _RawData implements RawData {
  _RawData.native(Pointer<Uint8> pointer, int length)
      : ptr = pointer,
        this.length = length,
        bytes = pointer.asTypedList(length);

  _RawData.fromList(this.bytes)
      : length = bytes.lengthInBytes,
        ptr = BytesPointer.fromList(bytes);

  @override
  Uint8List bytes;

  @override
  int length;

  @override
  Pointer<Uint8> ptr;

  @override
  void dispose() {
    bytes = Uint8List(0);
    length = 0;
    calloc.free(ptr);
  }
}
