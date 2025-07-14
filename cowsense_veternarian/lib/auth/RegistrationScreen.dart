import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import '../userCredential/VeteranProfileLocal.dart';
import '../userCredential/VeteranProfileModel.dart';
import '../services/VeteranProfileService.dart';
import 'package:flutter/services.dart';


class Registrationscreen extends StatefulWidget {
  static const String routeName = '/onboarding-registration';

  const Registrationscreen({super.key});

  @override
  State<Registrationscreen> createState() => _RegistrationscreenState();
}

class _RegistrationscreenState extends State<Registrationscreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _license = TextEditingController();
  DateTime? _dob;
  File? _cnicImage;
  String? _selectedCity;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickCnic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _cnicImage = File(pickedFile.path));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please complete all required fields.');
      return;
    }
    if (_dob == null) {
      _showSnackBar('Please select your date of birth.');
      return;
    }
    if (_cnicImage == null) {
      _showSnackBar('Please upload your CNIC image.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('No authenticated user found.');
      return;
    }

    final profile = VeteranProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      dob: _dob!,
      city: _selectedCity!,
      license: _license.text.trim(),
      cnicPath: _cnicImage!.path,
      licenseStatus: 'not-verified',
      completedRegistration: true,
    );

    try {
      await VeteranProfileService.saveProfile(profile);
      await VeteranProfileLocal.saveToLocal(profile);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      if (context.mounted) {
        _showSnackBar('Registration saved successfully.');
        Navigator.pushReplacementNamed(context, '/emailVerification');
      }
    } catch (e) {
      _showErrorDialog('Failed to save registration:\n${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: OnBoardingSlider(
            headerBackgroundColor: Colors.transparent,
            finishButtonText: 'Register',
            finishButtonStyle: FinishButtonStyle(
              backgroundColor: color.primary,
              elevation: 0,
              foregroundColor: color.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            totalPage: 3,
            background: const [SizedBox(), SizedBox(), SizedBox()],
            speed: 1.8,
            onFinish: _submit,
            pageBodies: [
              _pageWrapper(_buildPage1(theme)),
              _pageWrapper(_buildPage2(theme)),
              _pageWrapper(_buildPage3(theme)),
            ],
          ),
        ),
      ),
    );
  }

  /// Ensures every page has consistent constraints and scroll safety.
  Widget _pageWrapper(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  Widget _buildPage1(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Register your profile to get started as a certified veterinarian.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Full Name'),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phone,
          decoration: const InputDecoration(labelText: 'Phone Number'),
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Phone number is required';
            } else if (v.length < 11 || v.length > 13) {
              return 'Phone number must be between 11 and 13 digits';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Only allow digits
            LengthLimitingTextInputFormatter(13),  // Limit input length to 13 digits
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _dob != null
                ? _dob!.toLocal().toString().split(' ')[0]
                : 'Select Date of Birth',
            style: theme.textTheme.bodyLarge,
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickDOB,
        ),
      ],
    );
  }

  Widget _buildPage2(ThemeData theme) {
    return Column(
      children: [
        Text("Upload CNIC Picture", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 24),
        _cnicImage != null
            ? Image.file(_cnicImage!, height: 250, fit: BoxFit.cover)
            : Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.upload_file, size: 60),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _pickCnic,
          icon: const Icon(Icons.upload),
          label: const Text('Choose CNIC'),
        ),
      ],
    );
  }

  Widget _buildPage3(ThemeData theme) {
    // List of cities in Pakistan (you can expand this list as per your requirement)
    final List<String> _cities = [
      "Islamabad",
      "Karachi",
      "Lahore",
      "Quetta",
      "Peshawar",
      "Faisalabad",
      "Rawalpindi",
      "Multan",
      "Sialkot",
      "Gujranwala",
      "Bahawalpur",
      "Sargodha",
      "Hyderabad",
      "Mardan",
      "Sukkur",
      "Gujrat",
      "Swat",
      "Mingora",
      "Kotli",
      "Mirpur",
    ];

    return Column(
      children: [
        Text("Legal Info", style: theme.textTheme.headlineSmall),
        const SizedBox(height: 24),
        // City Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCity,
          onChanged: (newValue) {
            setState(() {
              _selectedCity = newValue;
            });
          },
          items: _cities.map<DropdownMenuItem<String>>((String city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'City of Practice',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            if (_selectedCity == null || _selectedCity!.isEmpty) {
              return 'Please select a city';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // License Input Field
        TextFormField(
          controller: _license,
          decoration: const InputDecoration(labelText: 'Govt License No.'),
          validator: (v) {
            // Check if the license contains only digits
            if (v == null || v.isEmpty) {
              return 'Required';
            }
            final licenseRegExp = RegExp(r'^\d+$');
            if (!licenseRegExp.hasMatch(v)) {
              return 'License must contain digits only';
            }
            return null;
          },
        ),
      ],
    );
  }
}
