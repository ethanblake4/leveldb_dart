import 'dart:ffi';

class leveldb_logger_t extends Struct {
  @Int32()
  external int version;
}
