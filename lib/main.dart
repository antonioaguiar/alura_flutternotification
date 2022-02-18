import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meetups/http/web.dart';
import 'package:meetups/models/device.dart';
import 'package:meetups/screens/events_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging _message = FirebaseMessaging.instance;

  String? _token = await _message.getToken();

  print("Token... $_token");
  setPushToken(_token);

  runApp(App());
}

void setPushToken(String? _token) async {
  String? brand;
  String? model;

  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String? prefToken = _prefs.getString("token") ?? "";
  bool? isSentTo = _prefs.getBool("sentto") ?? false;

  if (prefToken != _token || isSentTo == false) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      brand = androidInfo.brand ?? "";
      model = androidInfo.model ?? "";

      print("Device Android..: $model");
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      brand = 'Apple';
      model = iosInfo.utsname.machine ?? "";

      print("Device Apple..: $model");
    }

    Device device = new Device(brand: brand, model: model, token: _token);
    sendDevice(device).then((value) {
      if (value.statusCode == 200) {
        isSentTo = true;
      } else {
        isSentTo = false;
      }
      _prefs.setBool("sentto", isSentTo ?? false);
      _prefs.setString("token", _token ?? "");
    });
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev meetups',
      home: EventsScreen(),
    );
  }
}
