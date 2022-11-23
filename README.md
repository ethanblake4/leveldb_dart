# flutter_leveldb
A flutter plugin project to build leveldb for Android/iOS

## How To Build
- Step 1
    - Clone leveldb source project
  ```shell
    git submodule update --init --recursive
  ```

- Step 2
    - Make sure gradle sync successfully
    - Just run the app for debugging
    - Build release shared library
  ```shell
    gradle assembleRelease
  ```

- Step 3
    - Where to get built so files
  ```text
    The artifacts are placed in directory: example/build/flutter_leveldb/intermediates/cmake/debug(or release)/obj
  ```

## leveldb Source Project
[google/leveldb](https://github.com/google/leveldb)