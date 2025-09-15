import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

// class FCMSender {
//   static Future<String> _getAccessToken() async {
//     final jsonString = await rootBundle.loadString(
//       'assets/service-account.json',
//     );
//     final credentials = ServiceAccountCredentials.fromJson(
//       json.decode(jsonString),
//     );
//     final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
//     final client = await clientViaServiceAccount(credentials, scopes);
//     return client.credentials.accessToken.data;
//   }

//   static Future<void> sendEventNotification({
//     required String title,
//     required String body,
//     required String topic, // e.g., "all_events"
//     String? eventId,
//   }) async {
//     final token = await _getAccessToken();
//     final projectId = "event-buddy-92dfd";

//     final response = await http.post(
//       Uri.parse(
//         "https://fcm.googleapis.com/v1/projects/$projectId/messages:send",
//       ),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//       body: jsonEncode({
//         "message": {
//           "topic": topic,
//           "notification": {"title": title, "body": body},
//           "data": {"event_id": eventId ?? ""},
//         },
//       }),
//     );

//     print("FCM Response: ${response.body}");
//   }
// }
class FCMSender {
  static const String _fcmUrl =
      "https://fcm.googleapis.com/v1/projects/event-buddy-92dfd/messages:send";
  static const String _serverKey = "YOUR_SERVER_KEY"; // make sure correct

  static Future<void> sendEventNotification({
    required String title,
    required String body,
    required String topic,
    required String eventId,
  }) async {
    final payload = {
      "message": {
        "topic": topic,
        "notification": {"title": title, "body": body},
        "data": {
          "event_id": eventId,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "screen": "event_details",
          "type": "new_event",
        },
      },
    };

    final response = await http.post(
      Uri.parse(_fcmUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_serverKey",
      },
      body: jsonEncode(payload),
    );

    log("FCM Response: ${response.body}");
  }
}
