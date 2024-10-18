class NotificationPayload {
  final String fcmToken;
  final NotificationContent notification;
  final NotificationData data;

  NotificationPayload({
    required this.fcmToken,
    required this.notification,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      "message": {
        "token": fcmToken,
        "notification": notification.toMap(),
        "android": {
          "notification": {
            "notification_priority": "PRIORITY_MAX",
            "sound": "default",
          },
        },
        "apns": {
          "payload": {
            "aps": {
              "content_available": true,
            },
          },
        },
        "data": data.toMap(),
      },
    };
  }
}

class NotificationContent {
  final String title;
  final String body;

  NotificationContent({
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "body": body,
    };
  }
}

class NotificationData {
  final String? type;
  final String? id;
  final String clickAction;

  NotificationData({
    this.type,
    this.id,
    this.clickAction = "FLUTTER_NOTIFICATION_CLICK",
  });

  Map<String, dynamic> toMap() {
    return {
      "type": type,
      "id": id,
      "click_action": clickAction,
    };
  }
}
