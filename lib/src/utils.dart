import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:leveldb_dart/src/exceptions.dart';

T allocctx<T, U extends NativeType>(
  T Function(Pointer<U> v) f, [
  Pointer<U> Function()? allocationFunction,
]) {
  allocationFunction ??= () => calloc.allocate(0);

  final Pointer<U> v = allocationFunction();
  T result;
  try {
    result = f(v);
  } catch (e) {
    calloc.free(v);
    rethrow;
  }
  calloc.free(v);
  return result;
}

T errorHandler<T>(T Function(Pointer<Pointer<Char>> errptr) f) {
  final Pointer<Pointer<Char>> errptr = calloc.allocate(0);
  errptr.value = nullptr;

  T result;
  try {
    result = f(errptr);
  } catch (e) {
    final exception = _tryParseError(errptr);
    calloc.free(errptr);
    if ((exception != null) && (exception is LevelDBException)) {
      throw LevelDBException.combined(e as Exception, exception);
    } else {
      rethrow;
    }
  }

  final exception = _tryParseError(errptr);
  calloc.free(errptr);

  if (exception != null) {
    throw exception;
  }

  return result;
}

Exception? _tryParseError(Pointer<Pointer<Char>> errptr) {
  if (errptr.value == nullptr) return null;
  try {
    return LevelDBException.errptr(errptr.value.cast<Utf8>().toDartString());
  } catch (e) {
    return e as Exception;
  }
}
