#import "FlutterLeveldbPlugin.h"
#if __has_include(<flutter_leveldb/flutter_leveldb-Swift.h>)
#import <flutter_leveldb/flutter_leveldb-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_leveldb-Swift.h"
#endif

@implementation FlutterLeveldbPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterLeveldbPlugin registerWithRegistrar:registrar];
}
@end
