#import "FlutterOutreachPlugin.h"
#if __has_include(<flutter_outreach/flutter_outreach-Swift.h>)
#import <flutter_outreach/flutter_outreach-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_outreach-Swift.h"
#endif

@implementation FlutterOutreachPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterOutreachPlugin registerWithRegistrar:registrar];
}
@end
