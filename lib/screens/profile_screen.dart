import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/services/auth_service.dart';
import 'package:event_buddy/services/routes.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

class ProfileController extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _firestore;
  final ImagePicker _picker;

  ProfileController(this._authService, this._firestore, this._picker);

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isProcessingImage = false;
  bool _isDeletingProfile = false;
  String? _profileImageBase64;
  File? _selectedImageFile;
  Uint8List? _imageBytes;
  Map<String, String> _formData = {};

  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  bool get isProcessingImage => _isProcessingImage;
  bool get isDeletingProfile => _isDeletingProfile;
  String? get profileImageBase64 => _profileImageBase64;
  File? get selectedImageFile => _selectedImageFile;
  Uint8List? get imageBytes => _imageBytes;
  Map<String, String> get formData => _formData;

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

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
        _formData = {
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'email': userData['email'] ?? currentUser.email ?? '',
          'phone': userData['phone'] ?? '',
          'bio': userData['bio'] ?? '',
        };

        final imageData = userData['profileImage'];
        if (imageData != null && imageData.toString().isNotEmpty) {
          _profileImageBase64 = imageData.toString();
          try {
            _imageBytes = base64Decode(_profileImageBase64!);
          } catch (e) {
            log('Error decoding base64 image: $e');
            _profileImageBase64 = null;
            _imageBytes = null;
          }
        }
      } else {
        _formData = {'email': currentUser.email ?? ''};
      }
    } catch (e) {
      log('Error loading profile data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final imageFile = File(image.path);
        await _convertImageToBase64(imageFile);
      }
    } catch (e) {
      log('Error picking image: $e');
      rethrow;
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final imageFile = File(image.path);
        await _convertImageToBase64(imageFile);
      }
    } catch (e) {
      log('Error taking photo: $e');
      rethrow;
    }
  }

  Future<void> _convertImageToBase64(File imageFile) async {
    try {
      _isProcessingImage = true;
      _selectedImageFile = imageFile;
      notifyListeners();

      final bytes = await imageFile.readAsBytes();
      _profileImageBase64 = base64Encode(bytes);
      _imageBytes = bytes;
    } catch (e) {
      log('Error processing image: $e');
      rethrow;
    } finally {
      _isProcessingImage = false;
      notifyListeners();
    }
  }

  void removeImage() {
    _selectedImageFile = null;
    _profileImageBase64 = null;
    _imageBytes = null;
    notifyListeners();
  }

  Future<void> saveProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final profileData = {
        'firstName': _formData['firstName']?.trim() ?? '',
        'lastName': _formData['lastName']?.trim() ?? '',
        'email': _formData['email']?.trim() ?? '',
        'phone': _formData['phone']?.trim() ?? '',
        'bio': _formData['bio']?.trim() ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        profileData['profileImage'] = _profileImageBase64!;
      } else {
        profileData['profileImage'] = '';
      }

      final dataSize = profileData.toString().length;
      if (dataSize > 800000) {
        throw Exception('Profile data too large. Please use a smaller image.');
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

      _isEditing = false;
      _selectedImageFile = null;
    } catch (e) {
      log('Error saving profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProfile() async {
    _isDeletingProfile = true;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(currentUser.uid).delete();
      } else {
        final orgDoc = await _firestore
            .collection('organizers')
            .doc(currentUser.uid)
            .get();
        if (orgDoc.exists) {
          await _firestore
              .collection('organizers')
              .doc(currentUser.uid)
              .delete();
        }
      }

      await currentUser.delete();
    } catch (e) {
      log('Error deleting profile: $e');
      rethrow;
    } finally {
      _isDeletingProfile = false;
      notifyListeners();
    }
  }

  void updateFormField(String field, String value) {
    _formData = {..._formData, field: value};
    notifyListeners();
  }
}

final profileControllerProvider = ChangeNotifierProvider<ProfileController>((
  ref,
) {
  return ProfileController(
    ref.watch(authServiceProvider),
    ref.watch(firestoreProvider),
    ref.watch(imagePickerProvider),
  );
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider).loadUserData();
    });
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImagePickerDialog() {
    final controller = ref.read(profileControllerProvider);

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
                controller.pickImage().catchError((e) {
                  _showSnackBar('Error picking image: $e', Colors.red);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                controller.takePhoto().catchError((e) {
                  _showSnackBar('Error taking photo: $e', Colors.red);
                });
              },
            ),
            if (controller.profileImageBase64 != null ||
                controller.imageBytes != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  controller.removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProfile() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Delete Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your profile?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  ' This action cannot be undone!\n\n• Your profile data will be permanently deleted\n• You will be logged out immediately\n• All your information will be removed from the database',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await ref.read(profileControllerProvider).deleteProfile();
        _showSnackBar('Profile deleted successfully', Colors.green);

        if (mounted) {
          context.go(Routes.login);
        }
      } catch (e) {
        _showSnackBar('Error deleting profile: $e', Colors.red);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(profileControllerProvider);

    controller.updateFormField('firstName', _firstNameController.text);
    controller.updateFormField('lastName', _lastNameController.text);
    controller.updateFormField('email', _emailController.text);
    controller.updateFormField('phone', _phoneController.text);
    controller.updateFormField('bio', _bioController.text);

    try {
      await controller.saveProfile();
      _showSnackBar('Profile updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving profile: $e', Colors.red);
    }
  }

  Widget _buildProfileImage(ProfileController controller) {
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
            child: controller.isProcessingImage
                ? const Center(child: CircularProgressIndicator())
                : controller.imageBytes != null
                ? ClipOval(
                    child: Image.memory(
                      controller.imageBytes!,
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
                    ).withOpacity(0.7),
                  ),
          ),
          if (controller.isEditing)
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

  Widget _buildProfileForm(ProfileController controller) {
    if (_firstNameController.text != controller.formData['firstName']) {
      _firstNameController.text = controller.formData['firstName'] ?? '';
    }
    if (_lastNameController.text != controller.formData['lastName']) {
      _lastNameController.text = controller.formData['lastName'] ?? '';
    }
    if (_emailController.text != controller.formData['email']) {
      _emailController.text = controller.formData['email'] ?? '';
    }
    if (_phoneController.text != controller.formData['phone']) {
      _phoneController.text = controller.formData['phone'] ?? '';
    }
    if (_bioController.text != controller.formData['bio']) {
      _bioController.text = controller.formData['bio'] ?? '';
    }

    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(
        color: Colors.teal,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color.fromARGB(255, 22, 22, 22),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(child: _buildProfileImage(controller)),
          if (controller.isProcessingImage)
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  enabled: controller.isEditing,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 245, 243, 243),
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
                  enabled: controller.isEditing,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 243, 241, 241),
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
          TextFormField(
            controller: _emailController,
            enabled: false,
            style: const TextStyle(
              color: Color.fromARGB(255, 243, 241, 241),
              fontWeight: FontWeight.bold,
            ),
            decoration: inputDecoration.copyWith(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
              fillColor: const Color.fromARGB(255, 22, 22, 22),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            enabled: controller.isEditing,
            style: const TextStyle(
              color: Color.fromARGB(255, 243, 241, 241),
              fontWeight: FontWeight.bold,
            ),
            keyboardType: TextInputType.phone,
            decoration: inputDecoration.copyWith(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined, color: Colors.teal),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            enabled: controller.isEditing,
            maxLines: 3,
            style: const TextStyle(
              color: Color.fromARGB(255, 243, 241, 241),
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
    final controller = ref.watch(profileControllerProvider);
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.card,
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
              controller.setEditing(true);
            } else if (value == 'delete') {
              _deleteProfile();
            }
          },
          itemBuilder: (BuildContext context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'Delete Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
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
                await authService.signOut();
                if (context.mounted) {
                  context.go(
                    Routes.login,
                  ); 
                }
              }
            },
          ),
        ],
      ),
      body: controller.isLoading && !controller.isEditing
          ? const Center(child: CircularProgressIndicator())
          : controller.isDeletingProfile
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.red,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Deleting Profile...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please wait while we delete your account',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildProfileForm(controller),
                  ),
                ),
                if (controller.isEditing)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              controller.setEditing(false);
                              controller.loadUserData();
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
                            onPressed:
                                (controller.isLoading ||
                                    controller.isProcessingImage)
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
                            child: controller.isLoading
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
