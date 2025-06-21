[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/license/mit/)
[![Star on Github](https://img.shields.io/github/stars/ethanblake4/dart_eval?logo=github&colorB=orange&label=stars)](https://github.com/ethanblake4/dart_eval)
[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/ethanblake4)

An implementation of [LevelDB](https://github.com/google/leveldb) for Dart using dart:ffi. Based on [flutter_leveldb](https://pub.dev/packages/flutter_leveldb) by LiuJQ.

## How to build the LevelDB shared library
- Step 1: Clone the LevelDB repository with submodules:
  ```shell
    git clone --recurse-submodules https://github.com/google/leveldb.git
  ```

- Step 2: Build the LevelDB shared library:
  ```shell
    cd leveldb
    mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=on -DLEVELDB_BUILD_TESTS=off -DLEVELDB_BUILD_BENCHMARKS=off .
    cmake --build ..
  ```
  This will output the path of the shared library, which is typically named `libleveldb.so` on Linux, `libleveldb.dylib` on macOS, or `leveldb.dll` on Windows.

- Step 3: Copy the shared library to the Dart project.
  ```shell
    cp <path_to_your_shared_library> <path_to_your_dart_project>
  ```

## LevelDB Source Project
[google/leveldb](https://github.com/google/leveldb)