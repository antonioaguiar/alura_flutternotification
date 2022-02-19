import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart';
import 'package:meetups/models/device.dart';
import 'package:meetups/models/event.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://192.168.15.6:8080/api';

Future<List<Event>> getAllEvents() async {
  final response = await http.get(Uri.parse('$baseUrl/events'));

  if (response.statusCode == 200) {
    final List<dynamic> decodedJson = jsonDecode(response.body);
    return decodedJson.map((dynamic json) => Event.fromJson(json)).toList();
  } else {
    throw Exception('Falha ao carregar os eventos');
  }
}

Future<Response> sendDevice(Device device) async {
  final response = await http.post(
    Uri.parse('$baseUrl/devices'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
      <String, String>{
        'token': device.token ?? '',
        'modelo': device.model ?? '',
        'marca': device.brand ?? ''
      },
    ),
  );
  return response;
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
