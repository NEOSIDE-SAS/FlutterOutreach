import 'dart:async';

import 'package:flutter/services.dart';

class FlutterOutreach {
  static const MethodChannel _channel = MethodChannel('flutter_outreach');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static sendSMS(
      {required String text,
      required List<String> recipients,
      required List<String> urls,
      required String? access_token}) async {
    Map<String, dynamic> args = {
      'message': text,
      'recipients': recipients,
      'urls': urls,
      'access_token': access_token
    };
    await _channel.invokeMethod('sendSMS', args);
  }

  static sendInstantMessaging(
      {required String text,
      required List<String> recipients,
      required List<Map<String, String>> urls,
      String? access_token}) async {
    Map<String, dynamic> args = {
      'message': text,
      'recipients': recipients,
      'urls': urls,
      'access_token': access_token
    };
    await _channel.invokeMethod('sendInstantMessaging', args);
  }
}
