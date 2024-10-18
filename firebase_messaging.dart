import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:doc/core/helpers/notifications/notification_request_body_model.dart';
import 'package:doc/core/routing/routes.dart';
import 'package:doc/doc_app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class FirebaseMessagingHelper {
  // create instance of FCM
  final fcm = FirebaseMessaging.instance;

  // request permission
  Future<void> requestPermission() async {
    NotificationSettings settings = await fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("User granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log("User granted provisional permission");
    } else {
      log("User declined or has not accepted permission");
    }
  }

  /// init FCM
  Future<void> initNotifications() async {
    await requestPermission();
    String? firebaseMessagingToken = await fcm.getToken();
    log("firebaseMessagingToken : $firebaseMessagingToken");
    handelForegroundNotification();
    handelBackgroundNotificationClick();
    handelterminatedNotificationClick();
  }

  /// handel Foreground Notification
  Future<void> handelForegroundNotification() async {
    FirebaseMessaging.onMessage.listen(handleMessage);
  }

  /// handle FCM message
  Future<void> handleMessage(RemoteMessage? message) async {
    log("Foreground Notification Called");
    if (message == null) return;
    if (message.notification != null) {
      log("handle Message: ${message.notification?.title}");
      log("handle Message: ${message.notification?.body}");
    }
  }

  // Future<void> handelBackgroundNotificationClick() async {
  //   FirebaseMessaging.onMessageOpenedApp.listen(handleMessageOpen);
  // }

  Future<void> handelterminatedNotificationClick() async {
    await FirebaseMessaging.instance.getInitialMessage().then((message) {
      log("terminated Notification Called");
      if (message != null) {
        log("handle Message: ${message.notification?.title}");
        log("handle Message: ${message.notification?.body}");
        if (message.data["type"] == "notification") {
          navigatorKey.currentState
              ?.pushNamed(Routes.notificationView, arguments: message);
        }
        if (message.data["type"] == "hat") {
          navigatorKey.currentState
              ?.pushNamed(Routes.chatView, arguments: message);
        }
      }
    });
  }

  Future<void> handelBackgroundNotificationClick() async {
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessageOpen);
  }

  /// handle Interaction with FCM message
  void handleMessageOpen(RemoteMessage? message) {
    log("Background Notification Click Called");
    if (message == null) return;
    if (message.notification != null) {
      log("handle Message Open: ${message.notification?.title}");
      log("handle Message Open: ${message.notification?.body}");

      if (message.data["type"] == "notification") {
        navigatorKey.currentState
            ?.pushNamed(Routes.notificationView, arguments: message);
      } else if (message.data["type"] == "Chat") {
        navigatorKey.currentState
            ?.pushNamed(Routes.chatView, arguments: message);
      }
    }
  }

  /// send a message to multiple devices that have opted in to a particular topicز
  Future<void> subscribeToTopic() async {
    log("subscribeToTopic Called");
    await FirebaseMessaging.instance.subscribeToTopic('Doctors');
  }

  Future<void> unsubscribeFromTopic() async {
    log("unsubscribeFromTopic Called");
    await FirebaseMessaging.instance.unsubscribeFromTopic('Doctors');
  }

  /// get access token
  Future<String?> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "docdoc-distribution-cfe82",
      "private_key_id": "7b4d5f7bdb34f85339a1695a11687719b47b701b",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCr377MnYgsrfAG\nzF1nyvSjreOoTczhK1jvwcfBu1C4Nwhvzg3thG9IcbvihwgIsJKXBJua9Loo99iS\naeAD5QV25/Gv6Lcos6R53p5sVIfJjF8SUj1P/ygGBMZH2gmIVaAZs6WDnnNJq9kz\nNRNxzllPbOh0iy0dthkRfhS3trcHwopOqjCzn2DX1MoBJQL1iuPULAoUbzGfdBeA\nYj2YsaGm5RYYZXOHm7h2JUvDcxMDd3FOC9AK/q/leoWqPfSYljQSpy5yMfEFMK0D\nzGDvyU8Dtws2kIdT80dZ79A71zg1RStTMIppCxEe9RAujJZKOekJIMaw1EY7sqFE\nYrrbSJTbAgMBAAECggEARWXchoX9G/1Hc5dFB8m9KfHmgGiZlzmHeZeG7sSRfTBL\nacmLeiIFRP0XXgojxk51giDMK68xE6Wvfr7dQvVQVYil399ZRUfz23l2AkvHYCwb\nnywxsYFXScbXwN9bBf9826Pb6t8psc9/rdt6dHNbQGS7H4OqvdpvGM8N0ngmQy0y\neai2ruV2+gUlmgc+6d4TtIsF+vQgD6ZZgTWk2J0DHo9KHS6pGCjsMrBHgWrmZHDm\netnPN+8Y5vCQJBlilnZ0Jmc2ChwiqI7kd6IUcPV5qJuECoMr4QaUwDYyAMAMMPj6\nQwOJjQuAAyjp9k0D3p+Z0c7QxEsFzoYiGj4rut26UQKBgQDWA5mA0jwurFuEiCR9\nPNWAMltq3AoS8pD2VUgJgXBaeF73xf/81lhwDOZuh7bULM6EQHoMkUcXyP8ma584\nuTdQ3q7LK2UD/9i+aPkP764gzuyKklPCx+OvwcRunMuRzg4PeyEu/UzE7BlORUiQ\nJNUWkrYGtlsR21zEKNAV4oqA9QKBgQDNl8BKa7BqxOf3wfn0P6ySBhdV7auJ3kK4\nJiNV3u7RPMegPhKrMkJU0ThDtLezTbLcuavnGTkf0j81BRAXEEEVu6Xrku9lv7F3\njGLcuai6Z5a9Lse+hx9h+NhCEvY90I55gpl/++EnRnz6R+2weXLnTn6xUiS/V3R8\nfzv7lbjcjwKBgBivK5pfJU/g02Fy7np/dMSnikHGBWdwEOZIqdlm05WrwpBjhwYb\nlvG9mypuftj0HhHE+g7PBtsodL1ytletjULHnHOUmr8eWFqF8wwygewI0eGdxQl3\nUryn5cc4UIaNtLN2aTppPtyLutN7TEZL6UQEQfh+OfzSR13cszuC+KStAoGALAzp\nvIhaYmYSNbmwLq898IOxmE22RXID5aT2ST3c+aQGOcVTBq9cGwRBA/DCs35gZn65\n4Gg9Hx5TQK73BZoL9/Ye1NzEwo5SHgVMYXK+PkJXv+04CxC0nq9M1sttS01WWZ6r\n+Qok8d9eg9nJidhb0Ee3SZMKIJ1CbjJszbkExO0CgYAG17xL+Szyf+UPPjCEDr7F\nWaSL9mGqUU5XCCY3GMQP//cH7q/1/tqC5PbN/EsyBMGLYOSSAUx0qCNFzTn+hvXn\nAnV6zDLnE++j7fTHWHMYkSvqN1FxpNAzif6j4Zf2mv72fAjqMIPz8YYtwFY6zEtV\npo3ewbY9NZnF8zioaelDdg==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-w8f3a@docdoc-distribution-cfe82.iam.gserviceaccount.com",
      "client_id": "112716882023521959532",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-w8f3a%40docdoc-distribution-cfe82.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    try {
      http.Client client = await auth.clientViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

      auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
              auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
              scopes,
              client);

      client.close();
      log("Access Token: ${credentials.accessToken.data}"); // Print Access Token
      return credentials.accessToken.data;
    } catch (e) {
      log("Error getting access token: $e");
      return null;
    }
  }

  /// Send notification to device
  Future<void> sendNotifications(
      {required String title, required String notificationBody}) async {
    try {
      var serverKeyAuthorization = await getAccessToken();
      var token = await fcm.getToken();

      const String urlEndPoint =
          "https://fcm.googleapis.com/v1/projects/docdoc-distribution-cfe82/messages:send";

      Dio dio = Dio();
      dio.options.headers['Content-Type'] = 'application/json';
      dio.options.headers['Authorization'] = 'Bearer $serverKeyAuthorization';

      var response = await dio.post(urlEndPoint,
          data: NotificationPayload(
              fcmToken: token!,
              data: NotificationData(
                type: "type",
                id: "userId",
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
              ),
              notification: NotificationContent(
                title: title,
                body: notificationBody,
              )).toMap());

      log('Response Status Code: ${response.statusCode}');
      log('Response Data: ${response.data}');
    } catch (e) {
      log("Error sending notification: $e");
    }
  }

  Future<void> sendNotificationsToTopic(
      {required String title,
      required String notificationBody,
      required String topic}) async {
    try {
      log("send Notifications To Topic : $topic");

      var serverKeyAuthorization = await getAccessToken();
      const String urlEndPoint =
          "https://fcm.googleapis.com/v1/projects/docdoc-distribution-cfe82/messages:send";

      Dio dio = Dio();
      dio.options.headers['Content-Type'] = 'application/json';
      dio.options.headers['Authorization'] = 'Bearer $serverKeyAuthorization';

      var response = await dio.post(urlEndPoint,
          data: NotificationPayload(
              fcmToken: '/topics/$topic',
              data: NotificationData(
                type: "type",
                id: "userId",
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
              ),
              notification: NotificationContent(
                title: title,
                body: notificationBody,
              )).toMap());

      log('Response Status Code: ${response.statusCode}');
      log('Response Data: ${response.data}');
    } catch (e) {
      log("Error sending notification: $e");
    }
  }
}
