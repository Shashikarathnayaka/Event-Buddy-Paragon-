import 'dart:io';
import 'package:event_buddy/services/event_service.dart';
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
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();

  final EventService _eventService = EventService();
  File? _pickedImage;
  bool _saving = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
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
        organizer: FirebaseAuth.instance.currentUser?.uid,
        organizerId: '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event saved successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
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
                        hint: "Enter event name",
                      ).copyWith(
                        prefixIcon: const Icon(Icons.calendar_month),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
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
                      ? "Please enter event date"
                      : null,
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _eventLocationController,
                  decoration:
                      _inputDecoration(
                        "Event Location",
                        hint: "Enter event name",
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
                        hint: "Enter event name",
                      ).copyWith(
                        prefixIcon: const Icon(Icons.celebration),
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
                    onPressed: _saveEvent,
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
                    label: Text(_saving ? "Saving..." : "Save Event"),
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
}
