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
      "project_id": "****************************",
      "private_key_id": "*****************************",
      "private_key":"******************************",
      "client_email":
          "************************************",
      "client_id": "**************************************",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "*******************************",
      "client_x509_cert_url":
          "***************************************",
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
          "https://fcm.googleapis.com/v1/projects/*******PUT APP ID HERE*****/messages:send";

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
          "https://fcm.googleapis.com/v1/projects/***********PUT APP ID*********/messages:send";

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
