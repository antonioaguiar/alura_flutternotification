import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meetups/http/web.dart';
import 'package:meetups/screens/events_screen.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  //iniciar o firebase e setar o token para a notificação
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging _messaging = FirebaseMessaging.instance;

  //Solicitar autorização do usuário para uso de notificações
  NotificationSettings _settings = await _messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  //verificar se o cara autorizou
  if (_settings.authorizationStatus == AuthorizationStatus.authorized) {
    print(
        "Permissão para envio de notificações concedida\nStatus: ${_settings.authorizationStatus}");
    _pushNotificationHandler(_messaging);
  } else if (_settings.authorizationStatus == AuthorizationStatus.provisional) {
    print(
        "Permissão para envio provisório de notificações concedida\nStatus: ${_settings.authorizationStatus}");
    _pushNotificationHandler(_messaging);
  } else {
    print(
        "Permisão para notificação negada.\nStatus: ${_settings.authorizationStatus}");
  }

  runApp(App());
}

_pushNotificationHandler(FirebaseMessaging _messaging) async {
  String? _token = await _messaging.getToken();
  print("Token... $_token");

  //guardar o token para que o servidor possa enviar notificação
  setPushToken(_token);

  //foreground
  //listener para capturar as mensagens recebidas enquanto o app estiver
  //aberto em primeiro plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message != null) {
      print("Recebi a mensagem: ${message.data}");
      String titulo = message.data["titulo"] ?? "";
      String descricao = message.data["descricao"] ?? "";
      showMessageDialog(titulo, descricao);
    }

    if (message.notification != null) {
      print("Que continha a notificação..:  ${message.notification!.body}");
      String? titulo = message.notification!.title;
      String? descricao = message.notification!.body!;
      showMessageDialog(titulo!, descricao);
    }
  });

  //Background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //Terminated
  RemoteMessage? notificacao =
      await FirebaseMessaging.instance.getInitialMessage();
  if (notificacao != null) {
    if (notificacao.data[0].length > 0) {
      showMessageDialog(notificacao.data[0], notificacao.data[1]);
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Mensagem recebida em background\n${message.data}");
  if (message.notification != null) {
    print("Que continha a notificação..:  ${message.notification!.body}");
  }
}

//tela para mostrar as notificações mas ainda não existe "context"
//então vamos criar uma globalKey "navigatorKey" adicionar ao MaterialApp
void showMessageDialog(String title, String message) {
  Widget okButton = TextButton(
    onPressed: () => Navigator.pop(navigatorKey.currentContext!),
    child: Text("Ok"),
  );

  AlertDialog alerta = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [okButton],
  );

  showDialog(
    context: navigatorKey.currentContext!,
    builder: (BuildContext context) {
      return alerta;
    },
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev meetups',
      home: EventsScreen(),
      navigatorKey: navigatorKey,
    );
  }
}
