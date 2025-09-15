import 'dart:developer';
import 'dart:io';
import 'package:event_buddy/services/event_service.dart';
import 'package:event_buddy/services/auth_service.dart';
import 'package:event_buddy/services/notification_trigger_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key, required this.organizer});
  final String organizer;

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();

  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  File? _pickedImage;
  bool _saving = false;

  final String fcmServerKey = 'sever key';

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

  Future<void> _sendEventNotificationToAll(
    String eventId,
    String eventName,
    String eventDescription,
  ) async {
    try {
      final tokens = await _authService.getAllFCMTokens();

      if (tokens.isEmpty) {
        return;
      }

      final Map<String, dynamic> notification = {
        'title': 'New Event: $eventName',
        'body': eventDescription.length > 100
            ? '${eventDescription.substring(0, 100)}...'
            : eventDescription,
        'sound': 'default',
      };

      final Map<String, dynamic> data = {
        'event_id': eventId,
        'screen': 'event_details',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'type': 'new_event',
      };

      for (int i = 0; i < tokens.length; i += 500) {
        final batch = tokens.skip(i).take(500).toList();

        final Map<String, dynamic> message = {
          'registration_ids': batch,
          'notification': notification,
          'data': data,
          'priority': 'high',
          'android': {
            'notification': {
              'channel_id': 'event_notifications',
              'priority': 'high',
              'sound': 'default',
              'icon': '@mipmap/ic_launcher',
              'color': '#358A9E',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
                'alert': {
                  'title': notification['title'],
                  'body': notification['body'],
                },
              },
            },
          },
        };

        await _sendFCMMessage(message);

        if (i + 500 < tokens.length) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      log('Error sending notifications: $e');
    }
  }

  Future<void> _sendEventNotificationToUsers(
    String eventId,
    String eventName,
    String eventDescription,
  ) async {
    try {
      final tokens = await _authService.getUsersFCMTokens();

      if (tokens.isEmpty) {
        return;
      }

      await _sendNotificationBatch(
        tokens,
        eventId,
        eventName,
        eventDescription,
      );
    } catch (e) {
      log('Error sending notifications to users: $e');
    }
  }

  Future<void> _sendNotificationBatch(
    List<String> tokens,
    String eventId,
    String eventName,
    String eventDescription,
  ) async {
    final Map<String, dynamic> notification = {
      'title': 'New Event: $eventName',
      'body': eventDescription.length > 100
          ? '${eventDescription.substring(0, 100)}...'
          : eventDescription,
      'sound': 'default',
    };

    final Map<String, dynamic> data = {
      'event_id': eventId,
      'screen': 'event_details',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'type': 'new_event',
    };

    for (int i = 0; i < tokens.length; i += 500) {
      final batch = tokens.skip(i).take(500).toList();

      final Map<String, dynamic> message = {
        'registration_ids': batch,
        'notification': notification,
        'data': data,
        'priority': 'high',
        'android': {
          'notification': {
            'channel_id': 'event_notifications',
            'priority': 'high',
            'sound': 'default',
            'icon': '@mipmap/ic_launcher',
            'color': '#358A9E',
          },
        },
        'apns': {
          'payload': {
            'aps': {'sound': 'default', 'badge': 1},
          },
        },
      };

      await _sendFCMMessage(message);

      if (i + 500 < tokens.length) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _sendFCMMessage(Map<String, dynamic> message) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmServerKey',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        log(
          'Notification sent successfully: ${responseData['success']} sent, ${responseData['failure']} failed',
        );
      } else {
        log(
          'Failed to send notification: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      log('Error sending FCM message: $e');
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _saving = true);

      await _eventService.addEvent(
        name: _eventNameController.text.trim(),
        date: _eventDateController.text.trim(),
        location: _eventLocationController.text.trim(),
        description: _eventDescriptionController.text.trim(),
        imagePath: _pickedImage?.path,
        organizer: widget.organizer,
        organizerId: widget.organizer,
      );
      String? myToken = await FirebaseMessaging.instance.getToken();
      if (myToken != null) {
        await sendToTopic(
          topic: 'all',
          title: 'Hey we have New Event',
          body: _eventNameController.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event saved and notifications sent successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADD EVENT',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 53, 137, 158),
        foregroundColor: Colors.white,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _pickedImage != null
                      ? Image.file(
                          _pickedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          "assets/images/event_banner.jpg",
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 14),

                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.blueAccent),
                  label: const Text("Choose Event Image"),
                ),

                const SizedBox(height: 22),

                TextFormField(
                  controller: _eventNameController,
                  decoration:
                      _inputDecoration(
                        "Event Name",
                        hint: "Enter event name",
                      ).copyWith(
                        prefixIcon: const Icon(Icons.celebration),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Please enter event name"
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _eventDateController,
                  readOnly: true,
                  decoration:
                      _inputDecoration(
                        "Event Date",
                        hint: "Select event date",
                      ).copyWith(
                        prefixIcon: const Icon(Icons.calendar_month),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          "${pickedDate.day.toString().padLeft(2, '0')}/"
                          "${pickedDate.month.toString().padLeft(2, '0')}/"
                          "${pickedDate.year}";
                      setState(() {
                        _eventDateController.text = formattedDate;
                      });
                    }
                  },
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Please select event date"
                      : null,
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _eventLocationController,
                  decoration:
                      _inputDecoration(
                        "Event Location",
                        hint: "Enter event location",
                      ).copyWith(
                        prefixIcon: const Icon(Icons.location_on),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Please enter event location"
                      : null,
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _eventDescriptionController,
                  maxLines: 4,
                  decoration:
                      _inputDecoration(
                        "Event Description",
                        hint: "Enter event description",
                      ).copyWith(
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Please enter event description"
                      : null,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveEvent,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 22),
                    label: Text(
                      _saving
                          ? "Saving & Sending Notifications..."
                          : "Save Event",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 53, 137, 158),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 4,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }
}
