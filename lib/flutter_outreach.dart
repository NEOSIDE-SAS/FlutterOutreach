// ignore_for_file: non_constant_identifier_names, duplicate_ignore

import 'package:flutter/services.dart';

typedef OutreachCallback = void Function(String, bool);

class FlutterOutreach {
  static const MethodChannel _channel = MethodChannel('flutter_outreach');

  static sendSMS(
      {String? text,
      required List<String> recipients,
      required List<Map<String, String>> urls,
      // ignore: non_constant_identifier_names
      String? access_token,
      required OutreachCallback callback}) async {
    Map<String, dynamic> args = {
      'message': text,
      'recipients': recipients,
      'urls': urls,
      'access_token': access_token
    };
    Map<String, dynamic> result =
        Map<String, dynamic>.from(await _channel.invokeMethod('sendSMS', args));
    callback('SMS', result['isSuccess']);
  }

  static sendEmail(
      {String? text,
      required List<String> recipients,
      required List<Map<String, String>> urls,
      // ignore: non_constant_identifier_names
      String? access_token,
      required OutreachCallback callback,
      String? subject}) async {
    Map<String, dynamic> args = {
      'message': text,
      'subject': subject,
      'recipients': recipients,
      'urls': urls,
      'access_token': access_token
    };
    Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('sendEmail', args));
    callback('email', result['isSuccess']);
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
    Map<String, dynamic> result = Map<String, dynamic>.from(
        await _channel.invokeMethod('sendInstantMessaging', args));
    callback(
        (result['outreachType'] as String?) ?? '', result['isSuccess'] as bool);
  }
}
