import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_leveldb/flutter_leveldb.dart';
import 'package:flutter_leveldb/leveldb.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await FlutterLeveldb.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void testLevelDB() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    tempPath = path.join(tempPath, 'test.leveldb');

    final db = LevelDB.open(
      options: Options.byDefault(createIfMissing: true),
      filePath: tempPath,
    );

    final key = Uint8List.fromList('example'.codeUnits);
    final value = Uint8List.fromList('world'.codeUnits);

    void put() {
      final k = RawData.fromList(key);
      final v = RawData.fromList(value);
      db.put(k, v, ensured: true);
      k.dispose();
      v.dispose();
    }

    String get() {
      final k = RawData.fromList(key);
      final v = db.get(k);
      final result = String.fromCharCodes(v.bytes);
      k.dispose();
      v.dispose();
      return result;
    }

    put();
    final str = get();
    print(str);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
        floatingActionButton: FloatingActionButton(onPressed: testLevelDB, child: const Icon(Icons.add),),
      ),
    );
  }
}
