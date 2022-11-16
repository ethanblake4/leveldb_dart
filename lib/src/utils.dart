import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_leveldb/src/exceptions.dart';

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

T errorHandler<T>(T Function(Pointer<Pointer<Utf8>> errptr) f) {
  final Pointer<Pointer<Utf8>> errptr = calloc.allocate(0);
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

Exception? _tryParseError(Pointer<Pointer<Utf8>> errptr) {
  if (errptr.value == nullptr) return null;
  try {
    return LevelDBException.errptr(Utf8Pointer(errptr.value).toDartString());
  } catch (e) {
    return e as Exception;
  }
}
