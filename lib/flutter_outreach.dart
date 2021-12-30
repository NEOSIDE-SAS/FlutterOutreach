import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

typedef OutreachCallback = void Function(String, bool);

class FlutterOutreach {
  static const MethodChannel _channel = MethodChannel('flutter_outreach');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static sendSMS(
      {String? text,
      required List<String> recipients,
      required List<Map<String, String>> urls,
      String? access_token,
      required OutreachCallback callback}) async {
    Map<String, dynamic> args = {
      'message': text,
      'recipients': recipients,
      'urls': urls,
      'access_token': access_token
    };
    bool isSuccess = await _channel.invokeMethod('sendSMS', args);
    callback('email', isSuccess);
  }

  static sendEmail(
      {String? text,
      required List<String> recipients,
      required List<Map<String, String>> urls,
      String? access_token,
      required OutreachCallback callback}) async {
    Map<String, dynamic> args = {
      'message': text,
      'recipients': recipients,
      'urls': urls,
      'access_token': access_token
    };
    bool isSuccess = await _channel.invokeMethod('sendEmail', args);
    callback('email', isSuccess);
  }

  static sendInstantMessaging(
      {required String text,
      required List<String> recipients,
      required List<Map<String, String>> urls,
      String? access_token,
      required OutreachCallback callback}) async {
    Map<String, dynamic> args = {
      'message': text,
      'recipients': recipients,
      'urls': urls,
      'access_token': access_token
    };
    Map<String, dynamic> result = Map<String, dynamic>.from(await _channel.invokeMethod(
        'sendInstantMessaging', args));
    callback((result['outreachType'] as String?) ?? '', result['isSuccess'] as bool);
  }
}
