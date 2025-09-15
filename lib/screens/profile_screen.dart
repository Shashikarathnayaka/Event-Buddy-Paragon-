import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/Login_screen.dart';
import 'package:event_buddy/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isProcessingImage = false;

  String? _profileImageBase64;
  File? _selectedImageFile;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic>? userData;

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>?;
      } else {
        userDoc = await _firestore
            .collection('organizers')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>?;
        }
      }

      if (userData != null) {
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _emailController.text = userData['email'] ?? currentUser.email ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _bioController.text = userData['bio'] ?? '';

        final imageData = userData['profileImage'];
        if (imageData != null && imageData.toString().isNotEmpty) {
          _profileImageBase64 = imageData.toString();
          try {
            _imageBytes = base64Decode(_profileImageBase64!);
          } catch (e) {
            print('Error decoding base64 image: $e');
            _profileImageBase64 = null;
            _imageBytes = null;
          }
        }
      } else {
        _emailController.text = currentUser.email ?? '';
      }
    } catch (e) {
      _showSnackBar('Error loading profile data: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      setState(() => _isProcessingImage = true);
      final bytes = await imageFile.readAsBytes();
      _imageBytes = bytes;
      return base64Encode(bytes);
    } catch (e) {
      _showSnackBar('Error processing image: $e', Colors.red);
      return null;
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final imageFile = File(image.path);
        setState(() => _selectedImageFile = imageFile);
        final base64String = await _convertImageToBase64(imageFile);
        if (base64String != null) _profileImageBase64 = base64String;
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final imageFile = File(image.path);
        setState(() => _selectedImageFile = imageFile);
        final base64String = await _convertImageToBase64(imageFile);
        if (base64String != null) _profileImageBase64 = base64String;
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', Colors.red);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _profileImageBase64 = null;
      _imageBytes = null;
    });
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_profileImageBase64 != null || _imageBytes != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showSnackBar('No user logged in', Colors.red);
        return;
      }

      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        profileData['profileImage'] = _profileImageBase64!;
      } else {
        profileData['profileImage'] = '';
      }

      final dataSize = profileData.toString().length;
      if (dataSize > 800000) {
        _showSnackBar(
          'Profile data too large. Please use a smaller image.',
          Colors.red,
        );
        return;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update(profileData);
      } else {
        final orgDoc = await _firestore
            .collection('organizers')
            .doc(currentUser.uid)
            .get();
        if (orgDoc.exists) {
          await _firestore
              .collection('organizers')
              .doc(currentUser.uid)
              .update(profileData);
        } else {
          profileData['createdAt'] = FieldValue.serverTimestamp();
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set(profileData);
        }
      }

      setState(() {
        _isEditing = false;
        _selectedImageFile = null;
      });

      _showSnackBar('Profile updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving profile: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
              border: Border.all(
                color: const Color.fromARGB(255, 148, 214, 236),
                width: 3,
              ),
            ),
            child: _isProcessingImage
                ? const Center(child: CircularProgressIndicator())
                : _imageBytes != null
                ? ClipOval(
                    child: Image.memory(
                      _imageBytes!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 60,
                    color: const Color.fromARGB(
                      255,
                      53,
                      137,
                      158,
                      // ignore: deprecated_member_use
                    ).withOpacity(0.7),
                  ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 53, 137, 158),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(
        color: Colors.teal,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(child: _buildProfileImage()),
          if (_isProcessingImage)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'Processing image...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 30),

          // First + Last Name Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  enabled: _isEditing,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: inputDecoration.copyWith(
                    labelText: 'First Name',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.teal,
                    ),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'First name is required'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  enabled: _isEditing,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: inputDecoration.copyWith(
                    labelText: 'Last Name',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.teal,
                    ),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Last name is required'
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Email (disabled field)
          TextFormField(
            controller: _emailController,
            enabled: false,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            decoration: inputDecoration.copyWith(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
              fillColor: Colors.grey.shade200, // Disabled eka light grey
            ),
          ),

          const SizedBox(height: 16),

          // Phone
          TextFormField(
            controller: _phoneController,
            enabled: _isEditing,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            keyboardType: TextInputType.phone,
            decoration: inputDecoration.copyWith(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
            ),
          ),

          const SizedBox(height: 16),

          // Bio
          TextFormField(
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 3,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            decoration: inputDecoration.copyWith(
              labelText: 'Bio',
              prefixIcon: const Icon(
                Icons.account_box_outlined,
                color: Colors.teal,
              ),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 53, 137, 158),
        foregroundColor: Colors.white,

        leading: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: Color.fromARGB(255, 221, 226, 230),
            size: 28,
          ),
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          onSelected: (value) {
            if (value == 'edit') {
              setState(() => _isEditing = true);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading && !_isEditing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildProfileForm(),
                  ),
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                              _loadUserData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isProcessingImage)
                                ? null
                                : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                53,
                                137,
                                158,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
