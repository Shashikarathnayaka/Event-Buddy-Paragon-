// import 'dart:developer';
// import 'dart:io';
// import 'package:event_buddy/services/event_service.dart';
// import 'package:event_buddy/services/notification_trigger_service.dart';
// import 'package:event_buddy/theme/app_colors.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class AddEventScreen extends StatefulWidget {
//   const AddEventScreen({super.key, required this.organizer});

//   final String organizer;

//   @override
//   State<AddEventScreen> createState() => _AddEventScreenState();
// }

// class _AddEventScreenState extends State<AddEventScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final _eventNameController = TextEditingController();
//   final _eventDateController = TextEditingController();
//   final _eventTimeController = TextEditingController();
//   final _eventLocationController = TextEditingController();
//   final _eventDescriptionController = TextEditingController();

//   final _eventService = EventService();

//   File? _pickedImage;
//   bool _isSaving = false;
//   bool _isPickingImage = false;

//   @override
//   void dispose() {
//     _eventNameController.dispose();
//     _eventDateController.dispose();
//     _eventTimeController.dispose();
//     _eventLocationController.dispose();
//     _eventDescriptionController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     if (_isSaving) return;

//     try {
//       setState(() => _isPickingImage = true);

//       final pickedFile = await ImagePicker().pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1920,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );

//       if (pickedFile != null) {
//         setState(() => _pickedImage = File(pickedFile.path));
//       }
//     } catch (e) {
//       log('Error picking image: $e');
//       if (!mounted) return;
//       _showErrorSnackBar('Failed to pick image');
//     } finally {
//       if (mounted) setState(() => _isPickingImage = false);
//     }
//   }

//   Future<void> _selectDate() async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.dark(
//               primary: AppColors.primary,
//               onPrimary: Colors.white,
//               surface: AppColors.card,
//               onSurface: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (pickedDate != null) {
//       final formattedDate =
//           "${pickedDate.day.toString().padLeft(2, '0')}/"
//           "${pickedDate.month.toString().padLeft(2, '0')}/"
//           "${pickedDate.year}";
//       setState(() => _eventDateController.text = formattedDate);
//     }
//   }

//   Future<void> _selectTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//       builder: (context, child) {
//         return MediaQuery(
//           data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
//           child: Theme(
//             data: Theme.of(context).copyWith(
//               colorScheme: ColorScheme.dark(
//                 primary: AppColors.primary,
//                 onPrimary: Colors.white,
//                 surface: AppColors.card,
//                 onSurface: Colors.white,
//               ),
//             ),
//             child: child!,
//           ),
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() => _eventTimeController.text = picked.format(context));
//     }
//   }

//   Future<void> _saveEvent() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_pickedImage == null) {
//       final shouldContinue = await _showConfirmDialog(
//         'No Image Selected',
//         'Do you want to continue without an event image?',
//       );
//       if (shouldContinue != true) return;
//     }

//     try {
//       setState(() => _isSaving = true);

//       await _eventService.addEvent(
//         name: _eventNameController.text.trim(),
//         date: _eventDateController.text.trim(),
//         time: _eventTimeController.text.trim(),
//         location: _eventLocationController.text.trim(),
//         description: _eventDescriptionController.text.trim(),
//         imagePath: _pickedImage?.path,
//         organizer: widget.organizer,
//         organizerId: widget.organizer,
//       );

//       await _sendEventNotification();

//       if (!mounted) return;
//       _showSuccessSnackBar('Event created successfully!');
//       Navigator.pop(context, true);
//     } catch (e) {
//       log('Error saving event: $e');
//       if (!mounted) return;
//       _showErrorSnackBar('Failed to save event: ${e.toString()}');
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   Future<void> _sendEventNotification() async {
//     try {
//       final myToken = await FirebaseMessaging.instance.getToken();
//       if (myToken != null) {
//         await sendToTopic(
//           topic: 'all',
//           title: 'New Event Available! 🎉',
//           body: _eventNameController.text.trim(),
//         );
//         log('Event notification sent successfully');
//       }
//     } catch (e) {
//       log('Error sending notification: $e');
//     }
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   Future<bool?> _showConfirmDialog(String title, String message) {
//     return showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Continue'),
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _buildInputDecoration(
//     String label, {
//     String? hint,
//     IconData? icon,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: icon != null ? Icon(icon) : null,
//       filled: true,
//       fillColor: AppColors.inputBackground,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey.shade800),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: AppColors.primary, width: 2),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.red, width: 2),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.red, width: 2),
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Create New Event',
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: AppColors.card,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: AbsorbPointer(
//         absorbing: _isSaving,
//         child: Stack(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(20.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     _buildImageSection(),
//                     const SizedBox(height: 24),

//                     TextFormField(
//                       controller: _eventNameController,
//                       decoration: _buildInputDecoration(
//                         'Event Name',
//                         hint: 'Enter event name',
//                         icon: Icons.celebration,
//                       ),
//                       textCapitalization: TextCapitalization.words,
//                       validator: (v) => (v == null || v.trim().isEmpty)
//                           ? 'Please enter event name'
//                           : v.trim().length < 3
//                           ? 'Event name must be at least 3 characters'
//                           : null,
//                     ),
//                     const SizedBox(height: 16),

//                     Row(
//                       children: [
//                         Expanded(
//                           flex: 3,
//                           child: TextFormField(
//                             controller: _eventDateController,
//                             readOnly: true,
//                             decoration: _buildInputDecoration(
//                               'Event Date',
//                               hint: 'Select date',
//                               icon: Icons.calendar_month,
//                             ),
//                             onTap: _selectDate,
//                             validator: (v) => (v == null || v.trim().isEmpty)
//                                 ? 'Select date'
//                                 : null,
//                           ),
//                         ),
//                         const SizedBox(width: 12),

//                         Expanded(
//                           flex: 2,
//                           child: TextFormField(
//                             controller: _eventTimeController,
//                             readOnly: true,
//                             decoration: _buildInputDecoration(
//                               'Time',
//                               hint: 'Select time',
//                               icon: Icons.access_time,
//                             ),
//                             onTap: _selectTime,
//                             validator: (v) => (v == null || v.trim().isEmpty)
//                                 ? 'Select time'
//                                 : null,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     TextFormField(
//                       controller: _eventLocationController,
//                       decoration: _buildInputDecoration(
//                         'Event Location',
//                         hint: 'Enter event location',
//                         icon: Icons.location_on,
//                       ),
//                       textCapitalization: TextCapitalization.words,
//                       validator: (v) => (v == null || v.trim().isEmpty)
//                           ? 'Please enter event location'
//                           : null,
//                     ),
//                     const SizedBox(height: 16),

//                     TextFormField(
//                       controller: _eventDescriptionController,
//                       maxLines: 5,
//                       decoration: _buildInputDecoration(
//                         'Event Description',
//                         hint: 'Enter event description',
//                         icon: Icons.description,
//                       ),
//                       textCapitalization: TextCapitalization.sentences,
//                       validator: (v) => (v == null || v.trim().isEmpty)
//                           ? 'Please enter event description'
//                           : v.trim().length < 10
//                           ? 'Description must be at least 10 characters'
//                           : null,
//                     ),
//                     const SizedBox(height: 32),

//                     _buildSaveButton(),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),

//             if (_isSaving)
//               Container(
//                 color: Colors.black54,
//                 child: const Center(
//                   child: Card(
//                     child: Padding(
//                       padding: EdgeInsets.all(24.0),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           CircularProgressIndicator(),
//                           SizedBox(height: 16),
//                           Text(
//                             'Creating Event...',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImageSection() {
//     return Column(
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: _pickedImage != null
//               ? Image.file(
//                   _pickedImage!,
//                   height: 220,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                 )
//               : Container(
//                   height: 220,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade900,
//                     border: Border.all(color: Colors.grey.shade700),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.image_outlined,
//                         size: 64,
//                         color: Colors.grey.shade600,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'No image selected',
//                         style: TextStyle(color: Colors.grey.shade600),
//                       ),
//                     ],
//                   ),
//                 ),
//         ),
//         const SizedBox(height: 12),
//         OutlinedButton.icon(
//           onPressed: _isPickingImage ? null : _pickImage,
//           icon: _isPickingImage
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               : const Icon(Icons.add_photo_alternate),
//           label: Text(_isPickingImage ? 'Loading...' : 'Choose Event Image'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: AppColors.primary,
//             side: BorderSide(color: AppColors.primary),
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSaveButton() {
//     return SizedBox(
//       height: 56,
//       child: ElevatedButton.icon(
//         onPressed: _isSaving ? null : _saveEvent,
//         icon: _isSaving
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: Colors.white,
//                 ),
//               )
//             : const Icon(Icons.check_circle, size: 24),
//         label: Text(
//           _isSaving ? 'Creating Event...' : 'Create Event',
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 2,
//         ),
//       ),
//     );
//   }
// }

import 'dart:developer';
import 'dart:io';
import 'package:event_buddy/services/event_service.dart';
import 'package:event_buddy/services/notification_trigger_service.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key, required this.organizer});

  final String organizer;

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _eventNameController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventTimeController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _eventDescriptionController = TextEditingController();

  final _eventService = EventService();

  File? _pickedImage;
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventTimeController.dispose();
    _eventLocationController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isSaving) return;

    try {
      setState(() => _isPickingImage = true);

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _pickedImage = File(pickedFile.path));
      }
    } catch (e) {
      log('Error picking image: $e');
      if (!mounted) return;
      _showErrorSnackBar('Failed to pick image');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final formattedDate =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
      setState(() => _eventDateController.text = formattedDate);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.card,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _eventTimeController.text = picked.format(context));
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      final shouldContinue = await _showConfirmDialog(
        'No Image Selected',
        'Do you want to continue without an event image?',
      );
      if (shouldContinue != true) return;
    }

    try {
      setState(() => _isSaving = true);

      // Current user ගේ ID එක ගන්න
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      log('Creating event with organizerId: ${currentUser.uid}');

      await _eventService.addEvent(
        name: _eventNameController.text.trim(),
        date: _eventDateController.text.trim(),
        time: _eventTimeController.text.trim(),
        location: _eventLocationController.text.trim(),
        description: _eventDescriptionController.text.trim(),
        imagePath: _pickedImage?.path,
        organizer: widget.organizer, // Display name (e.g., "John Doe")
        organizerId: currentUser.uid, // Actual Firebase User ID
      );

      await _sendEventNotification();

      if (!mounted) return;
      _showSuccessSnackBar('Event created successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      log('Error saving event: $e');
      if (!mounted) return;
      _showErrorSnackBar('Failed to save event: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendEventNotification() async {
    try {
      final myToken = await FirebaseMessaging.instance.getToken();
      if (myToken != null) {
        await sendToTopic(
          topic: 'all',
          title: 'New Event Available! 🎉',
          body: _eventNameController.text.trim(),
        );
        log('Event notification sent successfully');
      }
    } catch (e) {
      log('Error sending notification: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Event',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.card,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _eventNameController,
                      decoration: _buildInputDecoration(
                        'Event Name',
                        hint: 'Enter event name',
                        icon: Icons.celebration,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter event name'
                          : v.trim().length < 3
                          ? 'Event name must be at least 3 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _eventDateController,
                            readOnly: true,
                            decoration: _buildInputDecoration(
                              'Event Date',
                              hint: 'Select date',
                              icon: Icons.calendar_month,
                            ),
                            onTap: _selectDate,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Select date'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _eventTimeController,
                            readOnly: true,
                            decoration: _buildInputDecoration(
                              'Time',
                              hint: 'Select time',
                              icon: Icons.access_time,
                            ),
                            onTap: _selectTime,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Select time'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _eventLocationController,
                      decoration: _buildInputDecoration(
                        'Event Location',
                        hint: 'Enter event location',
                        icon: Icons.location_on,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter event location'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _eventDescriptionController,
                      maxLines: 5,
                      decoration: _buildInputDecoration(
                        'Event Description',
                        hint: 'Enter event description',
                        icon: Icons.description,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter event description'
                          : v.trim().length < 10
                          ? 'Description must be at least 10 characters'
                          : null,
                    ),
                    const SizedBox(height: 32),

                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            if (_isSaving)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Creating Event...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _pickedImage != null
              ? Image.file(
                  _pickedImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isPickingImage ? null : _pickImage,
          icon: _isPickingImage
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate),
          label: Text(_isPickingImage ? 'Loading...' : 'Choose Event Image'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveEvent,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle, size: 24),
        label: Text(
          _isSaving ? 'Creating Event...' : 'Create Event',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
