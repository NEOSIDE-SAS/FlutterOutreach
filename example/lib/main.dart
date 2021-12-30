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
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              SizedBox(height: 100,),
              GestureDetector(
                onTap: (){
                  FlutterOutreach.sendEmail(text: "test", recipients: [
                    'avidanr@balink.net'
                  ], urls: [
                    {
                      'url' : 'http://techslides.com/demos/sample-videos/small.mp4',
                      'fileName' : 'big_buck_bunny_720p_1mb.mp4'
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
                    child: Text('Send Email',style: TextStyle(color: Colors.white),),
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: (){
                  FlutterOutreach.sendSMS(text: "test", recipients: [
                    '+972542425732'
                  ], urls: [
                    {
                      'url' : 'http://techslides.com/demos/sample-videos/small.mp4',
                      'fileName' : 'big_buck_bunny_720p_1mb.mp4'
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
                    child: Text('Send SMS',style: TextStyle(color: Colors.white),),
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: (){
                  FlutterOutreach.sendInstantMessaging(text: "test", recipients: [
                    '+972542425732'
                  ], urls: [
                    {
                      'url' : 'http://techslides.com/demos/sample-videos/small.mp4',
                      'fileName' : 'big_buck_bunny_720p_1mb.mp4'
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
                    child: Text('Send IM',style: TextStyle(color: Colors.white),),
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
