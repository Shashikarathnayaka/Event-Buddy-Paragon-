import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

Future<AutoRefreshingAuthClient> _getAuthClient() async {
  final serviceAccountString = await rootBundle.loadString(
    'assets/service_account.json',
  );
  final serviceAccountJson = json.decode(serviceAccountString);
  final accountCredentials = ServiceAccountCredentials.fromJson(
    serviceAccountJson,
  );

  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  final client = await clientViaServiceAccount(accountCredentials, scopes);
  return client;
}

Future<void> sendToToken({
  required String token,
  required String title,
  required String body,
  Map<String, String>? data,
}) async {
  final client = await _getAuthClient();
  final serviceAccountString = await rootBundle.loadString(
    'assets/service_account.json',
  );
  final projectId = json.decode(serviceAccountString)['project_id'];

  final url = Uri.parse(
    "https://fcm.googleapis.com/v1/projects/$projectId/messages:send",
  );

  final message = {
    "message": {
      "token": token,
      "notification": {"title": title, "body": body},
      "data": data ?? {},
    },
  };

  final response = await client.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(message),
  );

  print("Single token response: ${response.statusCode} -> ${response.body}");
  client.close();
}

Future<void> sendToTopic({
  required String topic,
  required String title,
  required String body,
  Map<String, String>? data,
}) async {
  final client = await _getAuthClient();
  final serviceAccountString = await rootBundle.loadString(
    'assets/service_account.json',
  );
  final projectId = json.decode(serviceAccountString)['project_id'];

  final url = Uri.parse(
    "https://fcm.googleapis.com/v1/projects/$projectId/messages:send",
  );

  final message = {
    "message": {
      "topic": topic,
      "notification": {"title": title, "body": body},
      "data": data ?? {},
    },
  };

  final response = await client.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(message),
  );

  print("Topic response: ${response.statusCode} -> ${response.body}");
  client.close();
}

Future<void> sendToTokenList({
  required List<String> tokens,
  required String title,
  required String body,
  Map<String, String>? data,
}) async {
  final client = await _getAuthClient();
  final serviceAccountString = await rootBundle.loadString(
    'assets/service_account.json',
  );
  final projectId = json.decode(serviceAccountString)['project_id'];

  final url = Uri.parse(
    "https://fcm.googleapis.com/v1/projects/$projectId/messages:send",
  );

  for (final token in tokens) {
    final message = {
      "message": {
        "token": token,
        "notification": {"title": title, "body": body},
        "data": data ?? {},
      },
    };

    final response = await client.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(message),
    );

    print("Token $token response: ${response.statusCode} -> ${response.body}");
  }

  client.close();
}
