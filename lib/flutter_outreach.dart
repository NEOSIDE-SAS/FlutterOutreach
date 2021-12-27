
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterOutreach {
  static const MethodChannel _channel = MethodChannel('flutter_outreach');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static sendSMS(String text, List<String> recipients, List<String> urls) async {
    Map<String, dynamic> args = {
      'message' : text,
      'recipients' : recipients,
      'urls' : urls
    };
    await _channel.invokeMethod('sendSMS', args);
  }

  static sendInstantMessaging(String text, List<String> recipients, List<String> urls) async {
    Map<String, dynamic> args = {
      'message' : text,
      'recipients' : recipients,
      'urls' : urls
    };
    await _channel.invokeMethod('sendInstantMessaging', args);
  }
}
