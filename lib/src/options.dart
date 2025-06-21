import 'dart:ffi';
import 'package:leveldb_dart/src/leveldb_bindings.dart';

import 'cache.dart';
import 'comparator.dart';
import 'env.dart';
import 'extensions.dart';
import 'filter_policy.dart';
import 'library.dart';
import 'native_wrapper.dart';

/// DB contents are stored in a set of blocks, each of which holds a
/// sequence of key,value pairs.  Each block may be compressed before
/// being stored in a file.  The following enum describes which
/// compression method (if any) is used to compress a block.
enum CompressionType { none, snappy }

/// Options to control the behavior of a database (passed to [LevelDB.open])
abstract class Options extends AnyStructure {
  /// Create an Options object with default values for all fields.
  factory Options.byDefault({
    Comparator? comparator,
    FilterPolicy? filterPolicy,
    bool createIfMissing = false,
    bool errorIfExists = false,
    bool paranoidChecks = false,
    Env? env,
    int writeBufferSize = 4 * 1024 * 1024,
    int maxOpenFiles = 1000,
    Cache? blockCache,
    int blockSize = 4 * 1024,
    int blockRestartInterval = 16,
    int maxFileSize = 2 * 1024 * 1024,
    CompressionType compressionType = CompressionType.snappy,
  }) =>
      _Options(
        Lib.levelDB,
        comparator: comparator,
        filterPolicy: filterPolicy,
        createIfMissing: createIfMissing,
        errorIfExists: errorIfExists,
        paranoidChecks: paranoidChecks,
        env: env,
        writeBufferSize: writeBufferSize,
        maxOpenFiles: maxOpenFiles,
        blockCache: blockCache,
        blockSize: blockSize,
        blockRestartInterval: blockRestartInterval,
        maxFileSize: maxFileSize,
        compressionType: compressionType,
      );

  /// Comparator used to define the order of keys in the table.
  /// Default: a comparator that uses lexicographic byte-wise ordering
  ///
  /// REQUIRES: The client must ensure that the comparator supplied
  /// here has the same name and orders keys *exactly* the same as the
  /// comparator provided to previous open calls on the same DB.
  Comparator? get comparator;

  /// If non-null, use the specified filter policy to reduce disk reads.
  /// Many applications will benefit from passing the result of
  /// [FilterPolicy.bloom()] here.
  FilterPolicy? get filterPolicy;

  /// If true, the database will be created if it is missing.
  bool get createIfMissing;

  /// If true, an error is raised if the database already exists.
  bool get errorIfExists;

  /// If true, the implementation will do aggressive checking of the
  /// data it is processing and will stop early if it detects any
  /// errors.  This may have unforeseen ramifications: for example, a
  /// corruption of one DB entry may cause a large number of entries to
  /// become unreadable or for the entire DB to become unopenable.
  bool get paranoidChecks;

  /// Use the specified object to interact with the environment,
  /// e.g. to read/write files, schedule background work, etc.
  /// Default: [Env.byDefault]
  Env? get env;

  // -------------------
  // Parameters that affect performance

  /// Amount of data to build up in memory (backed by an unsorted log
  /// on disk) before converting to a sorted on-disk file.
  ///
  /// Larger values increase performance, especially during bulk loads.
  /// Up to two write buffers may be held in memory at the same time,
  /// so you may wish to adjust this parameter to control memory usage.
  /// Also, a larger write buffer will result in a longer recovery time
  /// the next time the database is opened.
  int get writeBufferSize;

  /// Number of open files that can be used by the DB.  You may need to
  /// increase this if your database has a large working set (budget
  /// one open file per 2MB of working set).
  int get maxOpenFiles;

  /// Control over blocks (user data is stored in a set of blocks, and
  /// a block is the unit of reading from disk).
  ///
  /// If non-null, use the specified cache for blocks.
  /// If null, leveldb will automatically create and use an 8MB internal cache.
  Cache? get blockCache;

  /// Approximate size of user data packed per block.  Note that the
  /// block size specified here corresponds to uncompressed data.  The
  /// actual size of the unit read from disk may be smaller if
  /// compression is enabled.  This parameter can be changed dynamically.
  int get blockSize;
  set blockSize(int n);

  /// Number of keys between restart points for delta encoding of keys.
  /// This parameter can be changed dynamically.  Most clients should
  /// leave this parameter alone.
  int get blockRestartInterval;
  set blockRestartInterval(int n);

  /// Leveldb will write up to this amount of bytes to a file before
  /// switching to a new one.
  /// Most clients should leave this parameter alone.  However if your
  /// filesystem is more efficient with larger files, you could
  /// consider increasing the value.  The downside will be longer
  /// compactions and hence longer latency/performance hiccups.
  /// Another reason to increase this parameter might be when you are
  /// initially populating a large database.
  int get maxFileSize;

  /// Compress blocks using the specified compression algorithm.  This
  /// parameter can be changed dynamically.
  ///
  /// Default: [CompressionType.snappy], which gives lightweight but fast
  /// compression.
  ///
  /// Typical speeds of [CompressionType.snappy] on an Intel(R) Core(TM)2 2.4GHz:
  ///    ~200-500MB/s compression
  ///    ~400-800MB/s decompression
  /// Note that these speeds are significantly faster than most
  /// persistent storage speeds, and therefore it is typically never
  /// worth switching to kNoCompression.  Even if the input data is
  /// incompressible, the [CompressionType.snappy] implementation will
  /// efficiently detect that and will switch to uncompressed mode.
  CompressionType get compressionType;

  @override
  String toString() {
    return 'Options comparator: $comparator, filterPolicy: $filterPolicy, '
        'createIfMissing: $createIfMissing, errorIfExists: $errorIfExists, '
        'paranoidChecks: $paranoidChecks, env: $env, writeBufferSize: $writeBufferSize, '
        'maxOpenFiles: $maxOpenFiles, blockCache: $blockCache, blockSize: $blockSize, '
        'blockRestartInterval: $blockRestartInterval, maxFileSize: $maxFileSize, '
        'compressionType: $compressionType';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Options &&
        o.comparator == comparator &&
        o.filterPolicy == filterPolicy &&
        o.createIfMissing == createIfMissing &&
        o.errorIfExists == errorIfExists &&
        o.paranoidChecks == paranoidChecks &&
        o.env == env &&
        o.writeBufferSize == writeBufferSize &&
        o.maxOpenFiles == maxOpenFiles &&
        o.blockCache == blockCache &&
        o.blockSize == blockSize &&
        o.blockRestartInterval == blockRestartInterval &&
        o.maxFileSize == maxFileSize &&
        o.compressionType == compressionType;
  }

  @override
  int get hashCode {
    return comparator.hashCode ^
        filterPolicy.hashCode ^
        createIfMissing.hashCode ^
        errorIfExists.hashCode ^
        paranoidChecks.hashCode ^
        env.hashCode ^
        writeBufferSize.hashCode ^
        maxOpenFiles.hashCode ^
        blockCache.hashCode ^
        blockSize.hashCode ^
        blockRestartInterval.hashCode ^
        maxFileSize.hashCode ^
        compressionType.hashCode;
  }
}

extension on Options {
  // ignore: unused_element
  Options copyWith({
    Comparator? comparator,
    FilterPolicy? filterPolicy,
    bool? createIfMissing,
    bool? errorIfExists,
    bool? paranoidChecks,
    Env? env,
    int? writeBufferSize,
    int? maxOpenFiles,
    Cache? blockCache,
    int? blockSize,
    int? blockRestartInterval,
    int? maxFileSize,
    CompressionType? compressionType,
  }) {
    return _Options(
      Lib.levelDB,
      comparator: comparator ?? this.comparator,
      filterPolicy: filterPolicy ?? this.filterPolicy,
      createIfMissing: createIfMissing ?? this.createIfMissing,
      errorIfExists: errorIfExists ?? this.errorIfExists,
      paranoidChecks: paranoidChecks ?? this.paranoidChecks,
      env: env ?? this.env,
      writeBufferSize: writeBufferSize ?? this.writeBufferSize,
      maxOpenFiles: maxOpenFiles ?? this.maxOpenFiles,
      blockCache: blockCache ?? this.blockCache,
      blockSize: blockSize ?? this.blockSize,
      blockRestartInterval: blockRestartInterval ?? this.blockRestartInterval,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      compressionType: compressionType ?? this.compressionType,
    );
  }
}

class _Options extends AnyStructure implements Options {
  final LibLevelDB lib;

  @override
  Pointer<leveldb_options_t> ptr;

  @override
  final Cache? blockCache;

  @override
  final Comparator? comparator;

  @override
  final CompressionType compressionType;

  @override
  final bool createIfMissing;

  @override
  final Env? env;

  @override
  final bool errorIfExists;

  @override
  final FilterPolicy? filterPolicy;

  @override
  final int maxFileSize;

  @override
  final int maxOpenFiles;

  @override
  final bool paranoidChecks;

  @override
  final int writeBufferSize;

  @override
  int get blockRestartInterval => _blockRestartInterval;

  @override
  set blockRestartInterval(int v) {
    if (isDisposed) return;
    _blockRestartInterval = v;
    ptr.setBlockRestartInterval(v, lib);
  }

  int _blockRestartInterval;

  @override
  int get blockSize => _blockSize;

  @override
  set blockSize(int v) {
    if (isDisposed) return;
    _blockSize = v;
    ptr.setBlockSize(v, lib);
  }

  int _blockSize;

  _Options(
    this.lib, {
    this.blockCache,
    int blockSize = 4 * 1024,
    int blockRestartInterval = 16,
    this.comparator,
    this.compressionType = CompressionType.snappy,
    this.createIfMissing = true,
    this.env,
    this.errorIfExists = false,
    this.filterPolicy,
    this.maxFileSize = 2 * 1024 * 1024,
    this.maxOpenFiles = 1000,
    this.paranoidChecks = false,
    this.writeBufferSize = 4 * 1024 * 1024,
  })  : ptr = lib.leveldb_options_create()
          ..setBlockCache(blockCache, lib)
          ..setBlockSize(blockSize, lib)
          ..setBlockRestartInterval(blockRestartInterval, lib)
          ..setComparator(comparator, lib)
          ..setCompressionType(compressionType, lib)
          ..setCreateIfMissing(createIfMissing, lib)
          ..setEnv(env, lib)
          ..setErrorIfExists(errorIfExists, lib)
          ..setFilterPolicy(filterPolicy, lib)
          ..setMaxFileSize(maxFileSize, lib)
          ..setMaxOpenFiles(maxOpenFiles, lib)
          ..setParanoidChecks(paranoidChecks, lib)
          ..setWriteBufferSize(writeBufferSize, lib),
        _blockSize = blockSize,
        _blockRestartInterval = blockRestartInterval;

  @override
  void dispose() {
    if (isDisposed) return;
    lib.leveldb_options_destroy(ptr);
    ptr = nullptr;
  }
}

extension _OptionsSetup on Pointer<leveldb_options_t> {
  void setBlockCache(Cache? v, LibLevelDB lib) => v != null
      ? lib.leveldb_options_set_cache(this, v.ptr as Pointer<leveldb_cache_t>)
      : null;

  void setComparator(Comparator? v, LibLevelDB lib) => v != null
      ? lib.leveldb_options_set_comparator(
          this, v.ptr as Pointer<leveldb_comparator_t>)
      : null;

  void setCompressionType(CompressionType v, LibLevelDB lib) =>
      lib.leveldb_options_set_compression(this, v.associatedValue());
  void setCreateIfMissing(bool v, LibLevelDB lib) =>
      lib.leveldb_options_set_create_if_missing(this, v.toInt());

  void setEnv(Env? v, LibLevelDB lib) => v != null
      ? lib.leveldb_options_set_env(this, v.ptr as Pointer<leveldb_env_t>)
      : null;

  void setErrorIfExists(bool v, LibLevelDB lib) =>
      lib.leveldb_options_set_error_if_exists(this, v.toInt());

  void setFilterPolicy(FilterPolicy? v, LibLevelDB lib) => v != null
      ? lib.leveldb_options_set_filter_policy(
          this, v.ptr as Pointer<leveldb_filterpolicy_t>)
      : null;

  void setMaxFileSize(int v, LibLevelDB lib) =>
      lib.leveldb_options_set_max_file_size(this, v);

  void setMaxOpenFiles(int v, LibLevelDB lib) =>
      lib.leveldb_options_set_max_open_files(this, v);

  void setParanoidChecks(bool v, LibLevelDB lib) =>
      lib.leveldb_options_set_paranoid_checks(this, v.toInt());

  void setWriteBufferSize(int v, LibLevelDB lib) =>
      lib.leveldb_options_set_write_buffer_size(this, v);

  void setBlockRestartInterval(int v, LibLevelDB lib) =>
      lib.leveldb_options_set_block_restart_interval(this, v);

  void setBlockSize(int v, LibLevelDB lib) =>
      lib.leveldb_options_set_block_size(this, v);
}
