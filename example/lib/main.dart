// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_outreach/flutter_outreach.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fluuter outreach app'),
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              GestureDetector(
                onTap: () {
                  FlutterOutreach.sendEmail(
                      text: "test",
                      recipients: ['test@test.net'],
                      urls: [
                        {
                          'url':
                          'https://www.w3schools.com/css/paris.jpg',
                          'fileName': 'paris.jpg'
                        },
                        {
                          'url':
                          'https://www.w3schools.com/css/img_5terre_wide.jpg',
                          'fileName': 'img_5terre_wide.jpg'
                        }
                      ],
                      callback: (outreach, isSuccess) {
                        print(outreach);
                        print(isSuccess);
                      });
                },
                child: Container(
                  width: 140,
                  height: 45,
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Send Email',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: (){
                  FlutterOutreach.sendSMS(text: "test", recipients: [
                    '+33123456679'
                  ], urls: [
                    {
                      'url':
                      'https://www.w3schools.com/css/paris.jpg',
                      'fileName': 'paris.jpg'
                    },
                    {
                      'url':
                      'https://www.w3schools.com/css/img_5terre_wide.jpg',
                      'fileName': 'img_5terre_wide.jpg'
                    }
                  ], callback: (outreach, isSuccess) {
                    print(outreach);
                    print(isSuccess);
                  });
                },
                child: Container(
                  width: 140,
                  height: 45,
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Send SMS',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  FlutterOutreach.sendInstantMessaging(
                      text: "test",
                      recipients: ['+33123456679'],
                      urls: [

                      ],
                      callback: (outreach, isSuccess) {
                        print(outreach);
                        print(isSuccess);
                      });
                },
                child: Container(
                  width: 140,
                  height: 45,
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Send IM',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
